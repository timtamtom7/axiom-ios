import Foundation
import Network

/// R16: REST API for Mental Health Ecosystem
/// Lightweight HTTP server for belief data exchange with other health apps
final class HealthAPIService: ObservableObject, @unchecked Sendable {
    static let shared = HealthAPIService()

    @Published var isRunning: Bool = false
    @Published var lastError: String?

    private let listenerQueue = DispatchQueue(label: "com.axiom.healthapi.listener", qos: .userInitiated)
    private var listenerThread: Thread?
    private let port: UInt16 = 8766
    private var shouldContinue = false

    enum Endpoint: String {
        case beliefs = "/beliefs"
        case evidence = "/evidence"
        case stressTest = "/ai/stress-test"
        case healthStatus = "/health"
        case insights = "/ai/insights"
    }

    struct HealthStatus: Codable {
        let status: String
        let version: String
        let timestamp: Date
        let beliefsCount: Int
        let evidenceCount: Int
    }

    struct BeliefsResponse: Codable {
        let beliefs: [Belief]
        let total: Int
    }

    struct EvidenceResponse: Codable {
        let evidence: [Evidence]
        let beliefId: UUID?
        let total: Int
    }

    struct CreateBeliefRequest: Codable {
        let text: String
        let isCore: Bool?
        let score: Double?
    }

    struct CreateEvidenceRequest: Codable {
        let beliefId: UUID
        let text: String
        let type: String
        let confidence: Double?
    }

    struct StressTestRequest: Codable {
        let beliefId: UUID?
        let scenario: String?
    }

    struct StressTestResponse: Codable {
        let scenario: String
        let affectedBeliefs: [UUID]
        let recommendations: [String]
        let timestamp: Date
    }

    struct InsightsResponse: Codable {
        let totalBeliefs: Int
        let averageScore: Double
        let coreBeliefsCount: Int
        let evidenceTotal: Int
        let strongestBelief: Belief?
        let weakestBelief: Belief?
        let categoryBreakdown: [String: Int]
    }

    func start() throws {
        guard listenerThread == nil else { return }

        shouldContinue = true

        listenerThread = Thread { [weak self] in
            self?.runServer()
        }
        listenerThread?.name = "com.axiom.healthapi.server"
        listenerThread?.start()

        DispatchQueue.main.async {
            self.isRunning = true
            self.lastError = nil
        }
    }

    func stop() {
        shouldContinue = false
        listenerThread?.cancel()
        listenerThread = nil

        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    private func runServer() {
        let serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            DispatchQueue.main.async {
                self.lastError = "Failed to create socket"
                self.isRunning = false
            }
            return
        }

        var reuseAddr: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult >= 0 else {
            close(serverSocket)
            DispatchQueue.main.async {
                self.lastError = "Failed to bind socket"
                self.isRunning = false
            }
            return
        }

        listen(serverSocket, 5)

        while shouldContinue {
            var clientAddr = sockaddr_in()
            var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)

            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    accept(serverSocket, sockaddrPtr, &clientLen)
                }
            }

            guard clientSocket >= 0 else { continue }

            handleClient(socket: clientSocket)

            close(clientSocket)
        }

        close(serverSocket)
    }

    private func handleClient(socket: Int32) {
        var buffer = [UInt8](repeating: 0, count: 65536)
        let bytesRead = read(socket, &buffer, buffer.count)

        guard bytesRead > 0 else { return }

        let data = Data(buffer[0..<bytesRead])
        guard let response = processRequest(data: data) else { return }

        _ = write(socket, (response as NSData).bytes, response.count)
    }

    private nonisolated func getBeliefsSync() -> [Belief] {
        return MainActor.assumeIsolated {
            DatabaseService.shared.allBeliefs
        }
    }

    private func processRequest(data: Data) -> Data? {
        guard let requestString = String(data: data, encoding: .utf8) else { return nil }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let path = String(parts[1])

        // Find body (after blank line)
        var bodyString = ""
        if let blankLineIndex = lines.firstIndex(where: { $0.isEmpty }) {
            bodyString = lines[blankLineIndex...].joined(separator: "\r\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return routeRequest(method: method, path: path, body: bodyString)
    }

    private func routeRequest(method: String, path: String, body: String) -> Data? {
        var response: (status: Int, body: Data)?
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Get beliefs synchronously from main actor using a dedicated helper
        let beliefs = getBeliefsSync()

        switch path {
        case "/health", "/health/" where method == "GET":
            let status = HealthStatus(
                status: "healthy",
                version: "1.0.0",
                timestamp: Date(),
                beliefsCount: beliefs.count,
                evidenceCount: beliefs.flatMap { $0.evidenceItems }.count
            )
            if let bodyData = try? encoder.encode(status) {
                response = (200, bodyData)
            }

        case "/beliefs", "/beliefs/" where method == "GET":
            let resp = BeliefsResponse(beliefs: beliefs, total: beliefs.count)
            if let bodyData = try? encoder.encode(resp) {
                response = (200, bodyData)
            }

        case "/beliefs", "/beliefs/" where method == "POST":
            guard let bodyData = body.data(using: .utf8),
                  let createReq = try? JSONDecoder().decode(CreateBeliefRequest.self, from: bodyData) else {
                response = (400, "{\"error\":\"Invalid request\"}".data(using: .utf8)!)
                break
            }
            let newBelief = Belief(text: createReq.text, isCore: createReq.isCore ?? false)
            Task { @MainActor in
                DatabaseService.shared.addBelief(newBelief)
            }
            if let bodyData = try? encoder.encode(newBelief) {
                response = (201, bodyData)
            }

        case let path where path.hasPrefix("/evidence") && method == "GET":
            var beliefId: UUID?
            if let queryStart = path.firstIndex(of: "?"),
               let idString = path[queryStart...].split(separator: "=").last {
                beliefId = UUID(uuidString: String(idString))
            }

            let evidence: [Evidence]
            if let bid = beliefId,
               let belief = beliefs.first(where: { $0.id == bid }) {
                evidence = belief.evidenceItems
            } else {
                evidence = beliefs.flatMap { $0.evidenceItems }
            }
            let resp = EvidenceResponse(evidence: evidence, beliefId: beliefId, total: evidence.count)
            if let bodyData = try? encoder.encode(resp) {
                response = (200, bodyData)
            }

        case "/evidence", "/evidence/" where method == "POST":
            guard let bodyData = body.data(using: .utf8),
                  let createReq = try? JSONDecoder().decode(CreateEvidenceRequest.self, from: bodyData),
                  let type = EvidenceType(rawValue: createReq.type) else {
                response = (400, "{\"error\":\"Invalid request\"}".data(using: .utf8)!)
                break
            }
            let newEvidence = Evidence(
                beliefId: createReq.beliefId,
                text: createReq.text,
                type: type,
                confidence: createReq.confidence ?? 0.7
            )
            Task { @MainActor in
                DatabaseService.shared.addEvidence(newEvidence)
            }
            if let bodyData = try? encoder.encode(newEvidence) {
                response = (201, bodyData)
            }

        case "/ai/stress-test", "/ai/stress-test/" where method == "POST":
            let stressReq: StressTestRequest
            if let bodyData = body.data(using: .utf8),
               let req = try? JSONDecoder().decode(StressTestRequest.self, from: bodyData) {
                stressReq = req
            } else {
                stressReq = StressTestRequest(beliefId: nil, scenario: nil)
            }

            let stressResp = StressTestResponse(
                scenario: stressReq.scenario ?? "Standard stress test",
                affectedBeliefs: Array(beliefs.prefix(3).map { $0.id }),
                recommendations: [
                    "Practice deep breathing for 5 minutes",
                    "Challenge negative thoughts with evidence",
                    "Reach out to a support person",
                    "Use grounding techniques"
                ],
                timestamp: Date()
            )
            if let bodyData = try? encoder.encode(stressResp) {
                response = (200, bodyData)
            }

        case "/ai/insights", "/ai/insights/" where method == "GET":
            let avgScore = beliefs.isEmpty ? 0.0 : beliefs.map { $0.score }.reduce(0, +) / Double(beliefs.count)
            let insights = InsightsResponse(
                totalBeliefs: beliefs.count,
                averageScore: avgScore,
                coreBeliefsCount: beliefs.filter { $0.isCore }.count,
                evidenceTotal: beliefs.flatMap { $0.evidenceItems }.count,
                strongestBelief: beliefs.max(by: { $0.score < $1.score }),
                weakestBelief: beliefs.min(by: { $0.score < $1.score }),
                categoryBreakdown: [:]
            )
            if let bodyData = try? encoder.encode(insights) {
                response = (200, bodyData)
            }

        default:
            response = (404, "{\"error\":\"Not found\"}".data(using: .utf8)!)
        }

        guard let resp = response else { return nil }

        let headers = """
        HTTP/1.1 \(resp.status) \(statusText(resp.status))\r
        Content-Type: application/json\r
        Content-Length: \(resp.body.count)\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r\n

        """
        let headerData = headers.data(using: .utf8)!
        var fullResponse = headerData
        fullResponse.append(resp.body)
        return fullResponse
    }

    private func statusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 201: return "Created"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}
