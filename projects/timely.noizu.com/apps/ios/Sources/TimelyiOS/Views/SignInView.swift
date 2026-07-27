import SwiftUI
import TimelyKit

/// Sign in — presented, never imposed.
///
/// This screen is always reached from a banner or from Settings and always has
/// a "Not now". It is not a gate in front of the app, because the app does not
/// need one: local records are readable and writable without a session, and the
/// copy here says so rather than leaving the user to guess.
struct SignInView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var model = SessionViewModel()
    @State private var webAuth = WebAuthenticationPresenter()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        Text("You can keep working without signing in. Your records stay on "
                             + "this device and upload when you do.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "iphone.and.arrow.forward")
                            .foregroundStyle(.secondary)
                    }
                }

                if environment.configuration.oidc != nil {
                    Section {
                        Button {
                            Task {
                                await model.signInWithSSO(
                                    environment: environment, webAuth: webAuth
                                )
                                if environment.status.session == .active,
                                   !model.isPresentingWorkspaceChoice {
                                    dismiss()
                                }
                            }
                        } label: {
                            Label("Continue with single sign-on", systemImage: "person.badge.key")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isWorking)
                    } footer: {
                        Text("Opens your organization's sign-in page. Timely never sees your "
                             + "password.")
                    }
                }

                Section("Email and password") {
                    TextField("Email", text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $model.password)
                        .textContentType(.password)

                    Button {
                        Task {
                            await model.signInWithPassword(environment: environment)
                            if environment.status.session == .active,
                               !model.isPresentingWorkspaceChoice {
                                dismiss()
                            }
                        }
                    } label: {
                        if model.isWorking {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Sign in").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!model.canSubmitPassword)
                }

                if let error = model.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(TimelyTheme.danger)
                    }
                }

                if let notice = model.notice {
                    Section {
                        Text(notice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .sheet(isPresented: .constant(model.isPresentingWorkspaceChoice)) {
                WorkspaceChoiceView(model: model) { dismiss() }
            }
        }
    }
}

/// Which workspace, when the account belongs to more than one.
///
/// Never chosen automatically: derived ids are scoped to a workspace, so
/// picking wrong binds a week of records to the wrong tenant.
private struct WorkspaceChoiceView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var model: SessionViewModel
    let onChosen: () -> Void

    var body: some View {
        NavigationStack {
            List(model.workspaceChoices) { organization in
                Button {
                    Task {
                        await model.choose(organization, environment: environment)
                        onChosen()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(organization.name ?? "Workspace")
                            .font(.subheadline.weight(.medium))
                        Text(organization.id.canonicalString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Choose a workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { model.cancelWorkspaceChoice() }
                }
            }
        }
    }
}
