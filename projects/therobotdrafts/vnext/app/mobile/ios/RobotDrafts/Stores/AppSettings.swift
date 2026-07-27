import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var backendURLString: String {
        didSet { defaults.set(backendURLString, forKey: Keys.backendURL) }
    }

    @Published var projectId: String {
        didSet { defaults.set(projectId, forKey: Keys.projectId) }
    }

    private let defaults: UserDefaults

    var backendURL: URL {
        URL(string: backendURLString.trimmingCharacters(in: .whitespacesAndNewlines))
            ?? URL(string: "http://localhost:4000")!
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let bundled = Bundle.main.object(forInfoDictionaryKey: "RobotDraftsAPIBaseURL") as? String
        backendURLString = defaults.string(forKey: Keys.backendURL) ?? bundled ?? "http://localhost:4000"
        projectId = defaults.string(forKey: Keys.projectId) ?? ""
    }

    private enum Keys {
        static let backendURL = "RobotDrafts.backendURL"
        static let projectId = "RobotDrafts.projectId"
    }
}
