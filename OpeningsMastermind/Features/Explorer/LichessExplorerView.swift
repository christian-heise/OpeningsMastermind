//
//  LichessExplorerView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.05.23.
//

import SwiftUI
import ChessKit

struct LichessExplorerView: View {
    @ObservedObject var vm: ExploreViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing) {
                ForEach(vm.lichessResponse?.moves ?? [], id: \.self) { move in
                    Button() {
                        vm.makeLichessMove(san: move.san)
                    } label: {
                        Text(move.san)
                    }
                    .buttonStyle(.plain)
                        .frame(height: 20)
                        .if(move.san == vm.engineMove) { view in
                            view.foregroundColor(.green)
//                                .overlay() {
//                                RoundedRectangle(cornerRadius: 10).stroke().foregroundColor(.green)
//                            }
                        }
                }
            }
            VStack(alignment: .trailing) {
                ForEach(vm.lichessResponse?.moves ?? [], id: \.self) { move in
                    Button() {
                        vm.makeLichessMove(san: move.san)
                    } label: {
                        Text(Int(move.white + move.draws + move.black).formattedWithSeparator)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .buttonStyle(.plain)
                    .frame(height: 20)
                }
            }
            VStack {
                ForEach(vm.lichessResponse?.moves ?? [], id: \.self) { move in
                    Button() {
                        vm.makeLichessMove(san: move.san)
                    } label: {
                        ZStack {
                            GeometryReader { geo in
                                HStack(spacing: 0) {
                                    ZStack {
                                        Rectangle()
                                            .fill([207, 199, 207].getColor())
                                            .frame(width: geo.size.width * CGFloat(move.white)/CGFloat(move.white + move.black + move.draws))
                                        if Double(move.white)/Double(move.white + move.black + move.draws)*100 > 15 {
                                            Text(String(format:"%.0f%%", Double(move.white)/Double(move.white + move.black + move.draws)*100))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    ZStack {
                                        Rectangle()
                                            .fill([128, 108, 128].getColor())
                                            .frame(width: geo.size.width * CGFloat(move.draws)/CGFloat(move.white + move.black + move.draws))
                                        if Double(move.draws)/Double(move.white + move.black + move.draws)*100 > 15 {
                                            Text(String(format:"%.0f%%", Double(move.draws)/Double(move.white + move.black + move.draws)*100))
                                        }
                                    }
                                    ZStack {
                                        Rectangle()
                                            .fill([36, 30, 36].getColor())
                                            .frame(width: geo.size.width * CGFloat(move.black)/CGFloat(move.white + move.black + move.draws))
                                        if Double(move.black)/Double(move.white + move.black + move.draws)*100 > 15 {
                                            Text(String(format:"%.0f%%", Double(move.black)/Double(move.white + move.black + move.draws)*100))
                                                .foregroundColor([239, 235, 239].getColor())
                                        }
                                    }
                                }
                            }
                            Rectangle().stroke()
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 20)
                }
            }
        }
    }
}

/// Shown in place of the opening statistics when the user isn't signed in to
/// Lichess. The explorer host now requires authentication, so there is nothing
/// to display until they sign in. The prompt is dismissable, and an info button
/// explains why authentication is now required.
struct LichessSignInPrompt: View {
    let signIn: () async -> Void
    let onDismiss: () -> Void
    @State private var isSigningIn = false
    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 8) {
                Text("Sign in with Lichess to see opening statistics.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .overlay(alignment: .topTrailing) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss")
                    }
            HStack(spacing: 12) {
                Button {
                    Task {
                        isSigningIn = true
                        await signIn()
                        isSigningIn = false
                    }
                } label: {
                    Label("Sign in with Lichess", systemImage: "person.crop.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSigningIn)

                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Why sign in?")
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingInfo) {
            LichessAuthInfoView()
        }
    }
}

#Preview {
    LichessSignInPrompt(signIn: {}, onDismiss: {})
        .environment(\.locale, .init(identifier: "en"))
}

/// Explains why the Lichess opening explorer now requires authentication, with a
/// link to the official Lichess announcement.
struct LichessAuthInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private let blogURL = URL(string: "https://lichess.org/@/thibault/blog/the-opening-explorer-now-requires-authentication/FSWh9Zg3")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)

                    Text("Why sign in with Lichess?")
                        .font(.title2.bold())

                    Text("The opening statistics shown in the Explorer come from the Lichess opening explorer. Lichess now requires every app to authenticate before requesting this data, so OpeningsMastermind needs you to sign in with your Lichess account to load it.")

                    Text("Signing in is free and uses Lichess's official login — OpeningsMastermind never sees your password. You can sign out at any time in Settings.")

                    Link(destination: blogURL) {
                        Label("Read the Lichess announcement", systemImage: "arrow.up.right.square")
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Lichess Sign-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        return formatter
    }()
}
extension Int {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}

struct LichessExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        LichessExplorerView(vm: ExploreViewModel(database: DataBase(), appData: AppData()))
    }
}
