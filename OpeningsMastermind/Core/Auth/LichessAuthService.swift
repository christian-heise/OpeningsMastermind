//
//  LichessAuthService.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 22.06.26.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "LichessAuth")

/// Errors surfaced by the Lichess OAuth flow. `cancelled` is expected (user
/// dismissed the web sheet) and should be handled silently by callers.
enum LichessAuthError: Error, LocalizedError {
    case cancelled
    case invalidCallback
    case network
    case tokenExchangeFailed(status: Int, body: String)
    case accountFetchFailed(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Sign-in was cancelled."
        case .invalidCallback: return "Invalid sign-in response from Lichess."
        case .network: return "Could not reach Lichess. Check your connection."
        case let .tokenExchangeFailed(status, body):
            return "Lichess token exchange failed (HTTP \(status)): \(body)"
        case let .accountFetchFailed(status, body):
            return "Could not load your Lichess account (HTTP \(status)): \(body)"
        }
    }
}

/// Owns the user's Lichess OAuth2 (PKCE) session.
///
/// Lichess gated the opening-explorer host (`explorer.lichess.ovh`) behind
/// authentication, so every explorer request now needs an `Authorization:
/// Bearer` header. This service signs the user in with their own Lichess
/// account — PKCE means there is no client secret to embed in the app — and
/// vends the resulting access token to `ExploreViewModel`. The token is kept
/// in the keychain across launches.
@MainActor
@Observable
final class LichessAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {

    // Lichess does not require app pre-registration; the client_id is just a
    // public identifier and is NOT shown on the consent screen. What Lichess
    // displays there ("Allow <X> to access your account") is the redirect_uri's
    // scheme, so the scheme doubles as the app's name to the user — hence the
    // app-named, reverse-domain scheme below. It must use reverse-domain
    // notation: Lichess rejects "exotic"/dot-less schemes (e.g. a bare
    // "openingsmastermind"), so the scheme has to contain a dot.
    //
    // The scheme MUST be lowercase: URI schemes are case-insensitive (RFC 3986),
    // so Lichess lowercases it when recording the redirect_uri at the authorize
    // step, then compares that literally against the redirect_uri we send at
    // token exchange. A mixed-case scheme passes authorize but fails the token
    // request with `invalid_grant` ("issued for a different redirect_uri").
    private static let clientID = "openings-mastermind"
    private static let callbackScheme = "app.openingsmastermind"
    private static let redirectURI = "\(callbackScheme)://oauth/lichess"
    private static let authorizeURL = "https://lichess.org/oauth"
    private static let tokenURL = "https://lichess.org/api/token"
    private static let accountURL = "https://lichess.org/api/account"

    private let keychain = KeychainStore(
        service: Bundle.main.bundleIdentifier ?? "OpeningsMastermind",
        account: "lichess-oauth-token"
    )

    /// The current access token, or `nil` when signed out. Kept in sync with
    /// the keychain. Observed by the UI to show/hide the explorer.
    private(set) var token: String?

    var isSignedIn: Bool { token != nil }

    /// Keeps the in-flight session alive for the duration of the web flow.
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        self.token = keychain.read()
    }

    // MARK: - Sign in / out

    /// Runs the full OAuth2 PKCE flow and, on success, stores the token and
    /// returns the authenticated Lichess username. Throws `LichessAuthError`.
    @discardableResult
    func signIn() async throws -> String {
        let verifier = Self.makeCodeVerifier()
        let challenge = Self.codeChallenge(for: verifier)
        let state = UUID().uuidString

        let code = try await authorize(challenge: challenge, state: state)
        let token = try await exchange(code: code, verifier: verifier)

        keychain.save(token)
        self.token = token

        return try await fetchUsername(token: token)
    }

    func signOut() {
        keychain.delete()
        token = nil
    }

    /// Called by the explorer when a request comes back `401`, meaning the
    /// stored token was revoked or expired. Drops it so the UI reflects the
    /// signed-out state and prompts a fresh sign-in.
    func handleUnauthorized() {
        logger.warning("Lichess token rejected (401); signing out")
        signOut()
    }

    // MARK: - OAuth steps

    /// Presents the Lichess consent screen and returns the authorization code
    /// from the redirect.
    private func authorize(challenge: String, state: String) async throws -> String {
        var components = URLComponents(string: Self.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "state", value: state),
            // No scope needed: the opening explorer accepts any valid token.
            URLQueryItem(name: "scope", value: ""),
        ]

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: components.url!,
                callbackURLScheme: Self.callbackScheme
            ) { callbackURL, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: LichessAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: LichessAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }
        webAuthSession = nil

        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
        guard items?.first(where: { $0.name == "state" })?.value == state,
              let code = items?.first(where: { $0.name == "code" })?.value else {
            throw LichessAuthError.invalidCallback
        }
        return code
    }

    /// Exchanges the authorization code for an access token.
    private func exchange(code: String, verifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: verifier),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "client_id", value: Self.clientID),
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            logger.error("Lichess token request: network error")
            throw LichessAuthError.network
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200, let decoded = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            logger.error("Lichess token exchange failed (HTTP \(status, privacy: .public)): \(bodyString, privacy: .public)")
            throw LichessAuthError.tokenExchangeFailed(status: status, body: bodyString)
        }
        return decoded.accessToken
    }

    /// Fetches the signed-in user's Lichess username.
    private func fetchUsername(token: String) async throws -> String {
        var request = URLRequest(url: URL(string: Self.accountURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            logger.error("Lichess account request: network error")
            throw LichessAuthError.network
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200, let decoded = try? JSONDecoder().decode(AccountResponse.self, from: data) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            logger.error("Lichess account fetch failed (HTTP \(status, privacy: .public)): \(bodyString, privacy: .public)")
            throw LichessAuthError.accountFetchFailed(status: status, body: bodyString)
        }
        return decoded.username
    }

    // MARK: - PKCE helpers

    /// A high-entropy, URL-safe code verifier (RFC 7636).
    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    /// The S256 challenge derived from the verifier.
    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.keyWindow ?? ASPresentationAnchor()
    }

    // MARK: - Response models

    private struct TokenResponse: Decodable {
        let accessToken: String
        enum CodingKeys: String, CodingKey { case accessToken = "access_token" }
    }

    private struct AccountResponse: Decodable {
        let username: String
    }
}

private extension Data {
    /// Base64URL without padding, as required for PKCE.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
