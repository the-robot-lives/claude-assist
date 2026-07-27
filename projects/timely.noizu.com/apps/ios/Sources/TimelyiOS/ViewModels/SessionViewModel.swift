import Foundation
import Observation
import TimelyKit

/// Sign-in, and nothing else.
///
/// This view model has no say in whether the user may edit anything. It signs
/// in, it signs out, and it reports what happened. The app is fully usable in
/// every state it can be in, including "sign-in failed" and "never tried".
@MainActor
@Observable
final class SessionViewModel {

    var email = ""
    var password = ""

    private(set) var isWorking = false
    private(set) var errorMessage: String?
    private(set) var notice: String?

    /// True when single sign-on failed for a reason a retry will not fix, so
    /// the email/password form is the useful next step.
    private(set) var suggestsPasswordFallback = false

    /// Set when the account belongs to more than one workspace and the user has
    /// to say which. Choosing is never automatic — binding a week of records to
    /// the wrong tenant is not a mistake a retry fixes.
    private(set) var workspaceChoices: [OIDCAuthenticator.Organization] = []
    private var pendingTokens: AuthTokens?

    var isPresentingWorkspaceChoice: Bool { !workspaceChoices.isEmpty }

    var canSubmitPassword: Bool {
        !isWorking
            && email.contains("@")
            && password.count >= 8
    }

    func clearError() {
        errorMessage = nil
        suggestsPasswordFallback = false
    }

    // MARK: - Email and password

    func signInWithPassword(environment: AppEnvironment) async {
        guard let auth = environment.auth, canSubmitPassword else { return }

        isWorking = true
        errorMessage = nil
        notice = nil
        defer { isWorking = false }

        do {
            let tokens = try await auth.signIn(email: email, password: password)
            password = ""
            await finish(tokens: tokens, organizations: [], environment: environment)
        } catch let error as AuthError {
            errorMessage = error.description
        } catch {
            errorMessage = String(describing: error)
        }
    }

    // MARK: - Single sign-on

    func signInWithSSO(environment: AppEnvironment, webAuth: any WebAuthenticating) async {
        guard let authenticator = environment.makeOIDCAuthenticator(webAuth: webAuth) else {
            errorMessage = OIDCError.notConfigured.description
            return
        }

        isWorking = true
        errorMessage = nil
        notice = nil
        defer { isWorking = false }

        do {
            let result = try await authenticator.signIn()
            try await environment.auth?.adopt(result.tokens)
            await finish(
                tokens: result.tokens,
                organizations: result.organizations,
                environment: environment
            )
        } catch let error as OIDCError {
            // A cancellation is a choice, not a failure. Saying "sign-in
            // failed" to someone who tapped Cancel trains them to ignore errors.
            guard !error.isCancellation else { return }
            errorMessage = error.description
            // Some failures are permanent for this account or workspace.
            // Pointing at the password form beats inviting a retry that will
            // fail identically.
            suggestsPasswordFallback = error.suggestsPasswordFallback
        } catch {
            errorMessage = String(describing: error)
        }
    }

    // MARK: - Workspace selection

    func choose(_ organization: OIDCAuthenticator.Organization, environment: AppEnvironment) async {
        guard var tokens = pendingTokens else { return }
        tokens.workspaceID = organization.id
        try? await environment.auth?.adopt(tokens)

        workspaceChoices = []
        pendingTokens = nil
        await environment.adopt(workspaceID: organization.id, userID: tokens.userID)
    }

    func cancelWorkspaceChoice() {
        workspaceChoices = []
        pendingTokens = nil
        notice = "Signed in, but no workspace is selected yet. Your local records are unaffected."
    }

    // MARK: - Sign out

    /// Ends the session. Local records and the push queue survive — signing out
    /// is not a request to delete anyone's time.
    func signOut(environment: AppEnvironment) async {
        await environment.signOut()
        notice = "Signed out. Your records stay on this device and will sync when you sign in again."
    }

    // MARK: - Completion

    private func finish(
        tokens: AuthTokens,
        organizations: [OIDCAuthenticator.Organization],
        environment: AppEnvironment
    ) async {
        if let workspaceID = tokens.workspaceID {
            await environment.adopt(workspaceID: workspaceID, userID: tokens.userID)
            return
        }

        if organizations.count > 1 {
            pendingTokens = tokens
            workspaceChoices = organizations
            return
        }

        // Signed in, but the server did not name a workspace. The session is
        // real and the app keeps working on local records; only sync is idle.
        await environment.noteSignedIn(workspaceID: nil, userID: tokens.userID)
        notice = "Signed in. This account is not attached to a workspace yet, "
            + "so nothing will sync until it is."
    }
}
