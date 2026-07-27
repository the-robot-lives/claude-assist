import SwiftUI
import TimelyKit

/// The tab shell.
///
/// The original scaffold's Today / Timeline / Reports / Privacy split was
/// sound and mostly survives. Review is promoted to its own tab because
/// unanswered duplicate and overlap flags are the one thing in this app that
/// blocks an invoice, and burying them inside Today makes them easy to skip.
/// Privacy folds into Settings, where the screenshot gate belongs next to the
/// policy that constrains it.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        switch environment.phase {
        case .launching:
            ProgressView("Opening your records…")
                .controlSize(.large)

        case .failed(let message):
            StorageFailureView(message: message)

        case .ready:
            MainTabView()
        }
    }
}

private struct MainTabView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var reviewBadge = 0

    var body: some View {
        TabView {
            TodayView(onReviewCountChange: { reviewBadge = $0 })
                .tabItem { Label("Today", systemImage: "sun.horizon") }

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "rectangle.stack") }

            ReviewQueueView()
                .tabItem { Label("Review", systemImage: "checklist") }
                .badge(reviewBadge)

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.doc.horizontal") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(TimelyTheme.accent)
    }
}

/// Shown when the local database will not open.
///
/// Everything in this app is served from that database, so an empty timeline
/// would be a lie. Naming the failure is the only honest screen available.
private struct StorageFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: TimelyTheme.Space.card) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(TimelyTheme.danger)
            Text("Timely cannot open its records")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Your time records are not lost — this device cannot read them right now. "
                 + "Reinstalling would delete anything not yet synced.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(TimelyTheme.Space.page)
    }
}

// MARK: - Shared chrome

/// State-of-the-world banner.
///
/// It reports; it never blocks. Being offline, signed out, or holding an
/// expired token changes nothing about what the user can do on any screen
/// behind it, and the copy is written to make that explicit rather than to
/// imply a degraded mode.
struct SyncStatusBanner: View {
    @Environment(AppEnvironment.self) private var environment
    @Binding var isPresentingSignIn: Bool

    var body: some View {
        let status = environment.status

        if status.needsReauthentication {
            NoticeBanner(
                title: "Signed out on the server",
                message: "Your session expired. Everything here still works and your changes are "
                    + "queued — sign in again to resume syncing.",
                symbolName: "person.badge.key",
                tint: TimelyTheme.warning,
                actionTitle: "Sign in",
                action: { isPresentingSignIn = true }
            )
        } else if status.session == .none {
            NoticeBanner(
                title: environment.isUsingProvisionalWorkspace
                    ? "Working on this device only"
                    : "Not signed in",
                message: "Review, correct and add time now. Sign in whenever you like and "
                    + "everything you have done is uploaded then.",
                symbolName: "iphone.and.arrow.forward",
                tint: .secondary,
                actionTitle: "Sign in",
                action: { isPresentingSignIn = true }
            )
        } else if status.isOffline, status.queuedMutations > 0 {
            NoticeBanner(
                title: "\(status.queuedMutations) change\(status.queuedMutations == 1 ? "" : "s") waiting",
                message: "The server could not be reached. Your changes are saved here and will "
                    + "upload on their own.",
                symbolName: "icloud.slash",
                tint: .secondary
            )
        }
    }
}

/// A compact footer line: last sync, queue depth, workspace binding.
struct SyncFooter: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let status = environment.status

        VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
            HStack(spacing: TimelyTheme.Space.compact) {
                if status.isSyncing {
                    ProgressView().controlSize(.mini)
                    Text("Syncing…")
                } else if let lastSyncedAt = status.lastSyncedAt {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Synced \(TimelyFormat.clock(lastSyncedAt))")
                } else {
                    Image(systemName: "icloud.slash")
                    Text("Not synced yet")
                }

                if status.queuedMutations > 0 {
                    Text("· \(status.queuedMutations) queued")
                }
                Spacer(minLength: 0)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if environment.isUsingProvisionalWorkspace {
                Text("Records are held under a local workspace until you sign in.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, TimelyTheme.Space.compact)
    }
}
