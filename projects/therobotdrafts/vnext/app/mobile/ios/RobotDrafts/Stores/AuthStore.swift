import Foundation

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var organizations: [Organization] = []
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private var apiClient: APIClient
    private let tokenStore: TokenStore
    private(set) var tokens: AuthTokens?

    var isSignedIn: Bool {
        tokens?.accessToken.isEmpty == false
    }

    init(apiClient: APIClient, tokenStore: TokenStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.tokens = tokenStore.load()
    }

    func updateBackendURL(_ url: URL) {
        apiClient.baseURL = url
    }

    func signIn(email: String, password: String) async {
        isWorking = true
        errorMessage = nil

        do {
            let response = try await apiClient.login(email: email, password: password)
            let tokens = AuthTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            self.tokens = tokens
            self.user = response.user
            self.organizations = response.organizations ?? []
            tokenStore.save(tokens)
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    func refreshIfPossible() async {
        guard let refreshToken = tokens?.refreshToken else {
            return
        }

        do {
            let response = try await apiClient.refresh(refreshToken: refreshToken)
            let next = AuthTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? refreshToken
            )
            tokens = next
            tokenStore.save(next)
        } catch {
            signOut()
        }
    }

    func signOut() {
        tokens = nil
        user = nil
        organizations = []
        errorMessage = nil
        tokenStore.clear()
    }
}
