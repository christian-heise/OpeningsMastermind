//
//  WhatsNewView.swift
//  OpeningsMastermind
//
//  A one-time "What's New" splash presented by `ContentView` after an update
//  (and on first launch). It highlights the changes in the current version and
//  hosts the analytics opt-in so the user makes an informed consent choice.
//
//  Presentation is gated on `SettingsData.lastSeenWhatsNewVersion`: the screen
//  is shown once per marketing version, then that version is written back so it
//  never reappears. Update `Self.highlights` when bumping the version.
//

import SwiftUI

struct WhatsNewView: View {
    /// Drives the analytics toggle so the opt-in persists and reconfigures
    /// TelemetryDeck / `CrashReporter` through the same single gate as Settings.
    @State private var vm: SettingsViewModel

    @Environment(\.dismiss) private var dismiss

    init(appData: AppData) {
        self._vm = State(initialValue: SettingsViewModel(appData: appData))
    }

    /// The user-facing changes for the current version. Keep in sync with
    /// `fastlane/metadata/*/release_notes.txt`.
    private struct Highlight: Identifiable {
        let id = UUID()
        let icon: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
    }

    private static let highlights: [Highlight] = [
        Highlight(icon: "sparkles",
                  title: "A touch of Liquid Glass",
                  detail: "The app adopts Apple's new Liquid Glass design that comes with the latest iOS."),
        Highlight(icon: "globe",
                  title: "Now in German",
                  detail: "Switch language any time under Settings → General."),
        Highlight(icon: "square.and.arrow.down",
                  title: "More reliable import",
                  detail: "A rewritten PGN parser handles far more Lichess studies and PGN files correctly."),
        Highlight(icon: "bolt.shield",
                  title: "Fewer crashes",
                  detail: "Fixed crashes on deep or repetitive lines and a rare chess-engine crash."),
    ]

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(spacing: 18) {
                        ForEach(Self.highlights) { highlight in
                            highlightRow(highlight)
                        }
                    }

                    privacyCard(vm: $vm)
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.bar)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("AppIconImage")
                .resizable()
                .cornerRadius(76 / 6.4)
                .frame(width: 76, height: 76)
            Text("What's New")
                .font(.largeTitle.bold())
            Text("Version \(WhatsNewView.appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private func privacyCard(vm: Bindable<SettingsViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Help improve the app", systemImage: "chart.bar.doc.horizontal")
                .font(.headline)

            Toggle("Share anonymous analytics", isOn: vm.analyticsEnabled)
                .font(.subheadline.weight(.medium))

            Text("Openings Mastermind is built by one independent developer. With your permission, the app shares anonymous usage data and crash reports so I can see which features matter and fix problems quickly. There is no personal data and no advertising — just the insight that helps make the app better.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://telemetrydeck.com/privacy/")!) {
                Label("Analytics are handled by TelemetryDeck", systemImage: "arrow.up.right.square")
                    .font(.footnote)
            }

            Text("You can change this any time under Settings → Privacy.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func highlightRow(_ highlight: Highlight) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: highlight.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(highlight.title)
                    .font(.headline)
                Text(highlight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    /// The running app's marketing version, used both for the header label and
    /// the presentation gate in `ContentView`.
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
}

#Preview {
    WhatsNewView(appData: AppData())
}
#Preview {
    WhatsNewView(appData: AppData())
        .environment(\.locale, .init(identifier: "en"))
}
