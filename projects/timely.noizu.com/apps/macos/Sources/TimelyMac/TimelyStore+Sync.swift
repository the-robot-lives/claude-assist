import Foundation
import TimelyKit

/// Sync and authentication.
///
/// Kept in its own file because none of it is on the path of tracking time.
/// The app works completely without any of this: capture, edit, review and
/// report all read and write SQLite, and the only thing an absent or expired
/// session changes is whether the queue drains.
extension TimelyStore {

    /// Where the server lives. Overridable for local development.
    static var defaultBaseURL: URL {
        if let raw = ProcessInfo.processInfo.environment["TIMELY_API_BASE_URL"],
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://timely.noizu.com")!
    }

    // MARK: - Wiring

    /// Build the auth client and sync engine, and do an opening sync if a
    /// session already exists.
    ///
    /// Called once from `bootstrap()`. A failure here is not fatal and is not
    /// even reported as an error — no session is the ordinary state of a fresh
    /// install.
    func configureSync() async {
        guard let local else { return }

        let auth = AuthClient(baseURL: Self.defaultBaseURL)
        let api = TimelyAPIClient(baseURL: Self.defaultBaseURL, auth: auth)
        let engine = SyncEngine(
            store: local,
            client: api,
            auth: auth,
            workspaceID: workspaceIdentifier,
            deviceID: deviceIdentifier
        )

        setSyncCollaborators(auth: auth, engine: engine)

        if await auth.hasSession {
            await syncNow()
        } else {
            setSyncState(.offline)
        }
    }

    // MARK: - Sign in / out

    func signIn(email: String, password: String) async {
        guard let auth else {
            setSyncState(.failed("Sync is not configured yet."))
            return
        }

        setSyncState(.syncing)
        do {
            let tokens = try await auth.signIn(email: email, password: password)
            setSignedInEmail(email)

            // The rows created before sign-in are keyed under a provisional
            // workspace. Re-key them, or every one of them would be rejected
            // with `workspace_mismatch` and the user's offline week would never
            // reach the server.
            if let serverWorkspace = tokens.workspaceID {
                await adoptWorkspace(serverWorkspace)
            }

            await syncNow()
        } catch let error as AuthError {
            setSyncState(error.requiresReauthentication ? .signInRequired : .failed(error.description))
        } catch {
            setSyncState(.failed(error.localizedDescription))
        }
    }

    /// Ends the session. Deliberately leaves the local database and the push
    /// queue alone — signing out is not a request to erase months of tracked
    /// time, and the queue belongs to whoever signs in to the same workspace
    /// next.
    func signOut() async {
        guard let auth else { return }
        try? await auth.signOut()
        setSignedInEmail(nil)
        setSyncState(.offline)
    }

    /// Move local rows onto the workspace the server says this account owns.
    private func adoptWorkspace(_ serverWorkspaceID: UUID) async {
        guard let local else { return }
        guard let previous = adoptRealWorkspaceIdentifier(serverWorkspaceID) else { return }

        do {
            let report = try await local.rebindWorkspace(
                from: previous, to: serverWorkspaceID, deviceID: deviceIdentifier
            )
            if report.totalRows > 0 {
                // The engine was built against the provisional id, so it has to
                // be rebuilt before it can push any of the rebound rows.
                await configureSync()
            }
            await reload()
        } catch {
            setLastError("Could not attach your local history to your account: \(error.localizedDescription)")
        }
    }

    // MARK: - Syncing

    /// Push everything queued, then pull everything new.
    func syncNow() async {
        guard let engine else { return }

        setSyncState(.syncing)
        do {
            let outcome = try await engine.sync()

            if outcome.skipped {
                switch outcome.reason {
                case .noSession:
                    setSyncState(.offline)
                case .sessionExpired:
                    // The refresh token is dead. Local work is unaffected; the
                    // user just has to sign in again for it to leave the Mac.
                    setSyncState(.signInRequired)
                case .none:
                    setSyncState(.idle(lastSync: Date()))
                }
            } else {
                setSyncState(.idle(lastSync: Date()))
            }

            if outcome.rowsApplied > 0 || outcome.applied > 0 || outcome.sideEffects > 0 {
                await reload()
            } else {
                await refreshCounters()
            }
        } catch let error as SyncError {
            setSyncState(.failed(error.description))
        } catch {
            setSyncState(.failed(error.localizedDescription))
        }
    }

    /// Conflicts and rejections a person has to look at — `suspected_duplicate`
    /// and `billing_overlap` in particular. Nothing here resolves them.
    func pendingOutcomes() async -> [PendingOutcome] {
        guard let local else { return [] }
        return (try? await local.pendingOutcomes(workspaceID: workspaceIdentifier)) ?? []
    }

    func acknowledgeOutcome(_ outcome: PendingOutcome) async {
        guard let local else { return }
        try? await local.acknowledgeOutcome(mutationID: outcome.mutationID)
        await refreshCounters()
    }

    // MARK: - Screenshot blob upload

    /// Offer a screenshot's bytes to the server, if and only if both gates are
    /// open.
    ///
    /// There is deliberately no path in this app that uploads an image without
    /// going through `PrivacyGate`. `TimelyAPIClient.uploadScreenshotBlob`
    /// requires a `BlobUploadDecision`, and the only way to get one is for the
    /// gate to return `.success` — so "just upload it" does not compile.
    ///
    /// Returns the refusal when the gate is closed, so the UI can say something
    /// true about why rather than silently doing nothing.
    func offerScreenshotBytes(_ screenshot: Screenshot) async -> BlobUploadRefusal? {
        guard let api = apiClient else { return .workspacePolicyDisallows }

        let gate = PrivacyGate(
            workspaceAllowsBlobUpload: workspacePolicyAllowsBlobUpload,
            // The user's own "keep screenshots on this Mac" switch. Default is
            // on, so the gate is closed until they deliberately open it.
            deviceOptedInToBlobUpload: !settings.localOnlyScreenshots
        )

        let analysis = visionAnalyses.first { $0.screenshotID == screenshot.id }
        let censored = censoredScreenshots.contains { $0.screenshotID == screenshot.id }

        switch gate.evaluate(screenshot: screenshot, analysis: analysis, censored: censored) {
        case .failure(let refusal):
            return refusal

        case .success(let decision):
            let url = screenshotsURL.appendingPathComponent(screenshot.fileName)
            guard let data = try? Data(contentsOf: url) else {
                return .notEligible(screenshot.uploadState)
            }

            do {
                let result = try await api.uploadScreenshotBlob(
                    decision: decision, imageData: data
                )
                await applyBlobResult(result, to: screenshot)
                return nil
            } catch SyncError.blobRefused(_, let refusal) {
                // The server's half of the gate closed. Record its verdict.
                return refusal
            } catch {
                setLastError("Could not upload the screenshot: \(error.localizedDescription)")
                return nil
            }
        }
    }

    private func applyBlobResult(_ result: BlobUploadResult, to screenshot: Screenshot) async {
        guard let local else { return }
        var updated = screenshot
        updated.applyBlobUpload(result)
        // `markDirty: false` — this came from the server, so it is not a local
        // edit waiting to be pushed back at it.
        _ = try? await local.upsert(updated, markDirty: false)
        await reload()
    }
}
