import Foundation

enum DocumentSource: String, CaseIterable, Identifiable {
    case project = "Project"
    case fixtures = "Fixtures"

    var id: String { rawValue }
}

@MainActor
final class DocumentsStore: ObservableObject {
    @Published var source: DocumentSource = .fixtures
    @Published private(set) var documents: [DocumentSummary] = []
    @Published private(set) var selectedDocument: GraphDocument?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var apiClient: APIClient
    private let tokenStore: TokenStore

    init(apiClient: APIClient, tokenStore: TokenStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func updateBackendURL(_ url: URL) {
        apiClient.baseURL = url
    }

    func reload(projectId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            switch source {
            case .project:
                guard let accessToken = tokenStore.load()?.accessToken else {
                    throw APIError.notAuthenticated
                }
                documents = try await apiClient.listDocuments(projectId: projectId, accessToken: accessToken)
            case .fixtures:
                documents = try await apiClient.listFixtures()
            }

            if let first = documents.first {
                await select(first)
            } else {
                selectedDocument = nil
            }
        } catch {
            documents = []
            selectedDocument = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func select(_ summary: DocumentSummary) async {
        isLoading = true
        errorMessage = nil

        do {
            switch source {
            case .project:
                guard let accessToken = tokenStore.load()?.accessToken else {
                    throw APIError.notAuthenticated
                }
                selectedDocument = try await apiClient.loadDocument(id: summary.id, accessToken: accessToken)
            case .fixtures:
                selectedDocument = try await apiClient.loadFixture(id: summary.id)
            }
        } catch {
            selectedDocument = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
