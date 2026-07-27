import Foundation

/// The HTTP seam.
///
/// Every network call in the package goes through this protocol, so the sync
/// tests drive real conflict-matrix scenarios against a scripted transport
/// rather than a live server. A test that needs a network is a test that does
/// not run in CI.
public protocol HTTPTransporting: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransporting {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public init(timeout: TimeInterval) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        // The sync engine owns retry and ordering; URLSession retrying behind
        // its back would reorder a FIFO queue.
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw SyncError.transport("Non-HTTP response")
            }
            return (data, http)
        } catch let error as SyncError {
            throw error
        } catch {
            throw SyncError.transport(error.localizedDescription)
        }
    }
}

/// A transport that answers from a script. Tests only.
public final class StubTransport: HTTPTransporting, @unchecked Sendable {

    public struct Exchange: Sendable {
        public let status: Int
        public let body: Data
        public let headers: [String: String]

        public init(status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
            self.status = status
            self.body = body
            self.headers = headers
        }

        public static func json(_ status: Int = 200, _ text: String) -> Exchange {
            Exchange(
                status: status,
                body: Data(text.utf8),
                headers: ["Content-Type": "application/json"]
            )
        }
    }

    private let lock = NSLock()
    private var handler: (@Sendable (URLRequest, Int) -> Exchange)?
    private var scripted: [Exchange] = []
    private var recorded: [URLRequest] = []
    private var recordedBodies: [Data] = []

    public init() {}

    /// Answer each request from a queue, in order.
    public func script(_ exchanges: [Exchange]) {
        lock.lock(); defer { lock.unlock() }
        scripted = exchanges
    }

    /// Answer with a closure. The `Int` is the zero-based request index.
    public func respond(_ handler: @escaping @Sendable (URLRequest, Int) -> Exchange) {
        lock.lock(); defer { lock.unlock() }
        self.handler = handler
    }

    public var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return recorded
    }

    public var bodies: [Data] {
        lock.lock(); defer { lock.unlock() }
        return recordedBodies
    }

    public var requestCount: Int {
        lock.lock(); defer { lock.unlock() }
        return recorded.count
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // All mutable state is touched inside this synchronous helper. `NSLock`
        // is unavailable from an async context because holding one across a
        // suspension point can deadlock the cooperative pool; confining it to a
        // non-async function is the sanctioned pattern.
        let exchange = try nextExchange(for: request)

        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: exchange.status,
            httpVersion: "HTTP/1.1",
            headerFields: exchange.headers
        )!
        return (exchange.body, response)
    }

    private func nextExchange(for request: URLRequest) throws -> Exchange {
        lock.lock(); defer { lock.unlock() }

        let index = recorded.count
        recorded.append(request)
        // `httpBody` is nil for a stream-backed request; the package always sets
        // `httpBody` directly, so this is sufficient and avoids a stream read.
        recordedBodies.append(request.httpBody ?? Data())

        if let handler {
            return handler(request, index)
        }
        guard !scripted.isEmpty else {
            throw SyncError.transport("StubTransport ran out of scripted responses")
        }
        return scripted.removeFirst()
    }
}
