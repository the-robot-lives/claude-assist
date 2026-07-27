import SwiftUI

struct LoginPanel: View {
    @EnvironmentObject private var authStore: AuthStore

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)

            SecureField("Password", text: $password)
                .textContentType(.password)

            Button {
                Task { await authStore.signIn(email: email, password: password) }
            } label: {
                Label(authStore.isWorking ? "Signing In" : "Sign In", systemImage: "key.fill")
            }
            .disabled(email.isEmpty || password.isEmpty || authStore.isWorking)

            if let error = authStore.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Brand.hot)
            }
        }
        .textFieldStyle(.roundedBorder)
    }
}
