/*
Swift HTTP Server
=================
A simple HTTP server built with SwiftNIO that responds to requests on port 8080.

How to run:
1. Ensure you have Swift 5.7+ installed.
2. In the terminal, navigate to this directory.
3. Build the server:
   $ swift build
4. Run the server:
   $ swift run
5. The server will start on http://127.0.0.1:8080

Available endpoints:
- GET  /          - Welcome message
- GET  /hello     - Hello World
- POST /echo      - Echo endpoint
- GET  /questions - Returns list of survey questions (3-5 items)
- POST /answers   - Accepts user answers and stores them in memory

To test with curl:
$ curl http://127.0.0.1:8080/
$ curl http://127.0.0.1:8080/hello
$ curl -X POST http://127.0.0.1:8080/echo
$ curl http://127.0.0.1:8080/questions
$ curl -X POST http://127.0.0.1:8080/answers -H "Content-Type: application/json" -d '{"answers": [{"questionId": 1, "answer": "Yes"}, {"questionId": 2, "answer": "No"}]}'

To stop the server, press Ctrl+C.
*/

import NIO
import NIOHTTP1
import Foundation

// MARK: - Data Models

struct Question: Codable {
    let id: Int
    let text: String
    let type: String  // "text", "singleChoice", "multipleChoice"
    let options: [String]?
}

struct Answer: Codable {
    let questionId: Int
    let answer: String
}

struct AnswerSubmission: Codable {
    let answers: [Answer]
}

struct ResponseMessage: Codable {
    let message: String
    let receivedCount: Int
    let totalAnswersStored: Int
}

// MARK: - In-memory Storage

class AnswerStore {
    static let shared = AnswerStore()
    private init() {}
    
    private var allAnswers: [Answer] = []
    private let lock = NSLock()
    
    func addAnswers(_ answers: [Answer]) {
        lock.lock()
        defer { lock.unlock() }
        allAnswers.append(contentsOf: answers)
    }
    
    func getAllAnswers() -> [Answer] {
        lock.lock()
        defer { lock.unlock() }
        return allAnswers
    }
    
    func getAnswerCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return allAnswers.count
    }
}

// MARK: - Predefined Questions

let predefinedQuestions: [Question] = [
    Question(
        id: 1,
        text: "How satisfied are you with our service?",
        type: "singleChoice",
        options: ["Very satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very dissatisfied"]
    ),
    Question(
        id: 2,
        text: "What is your age group?",
        type: "singleChoice",
        options: ["Under 18", "18-24", "25-34", "35-44", "45-54", "55+"]
    ),
    Question(
        id: 3,
        text: "How did you hear about us?",
        type: "multipleChoice",
        options: ["Social media", "Friend recommendation", "Online advertisement", "Search engine", "Other"]
    ),
    Question(
        id: 4,
        text: "What features would you like to see improved?",
        type: "text",
        options: nil
    ),
    Question(
        id: 5,
        text: "Would you recommend our service to others?",
        type: "singleChoice",
        options: ["Definitely yes", "Probably yes", "Not sure", "Probably not", "Definitely not"]
    )
]

// MARK: - JSON Encoding/Decoding Utilities

func encodeJSON<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}

func decodeJSON<T: Decodable>(_ string: String, as type: T.Type) -> T? {
    guard let data = string.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
}

// MARK: - Router

/// Simple router that maps (method, path) to a handler
struct Router {
    typealias Handler = (HTTPRequestHead, String?, ChannelHandlerContext) -> (HTTPResponseHead, String)
    
    private var routes: [String: Handler] = [:]
    
    mutating func addRoute(method: HTTPMethod, path: String, handler: @escaping Handler) {
        let key = "\(method) \(path)"
        routes[key] = handler
    }
    
    func handle(request: HTTPRequestHead, body: String?, context: ChannelHandlerContext) -> (HTTPResponseHead, String)? {
        let key = "\(request.method) \(request.uri)"
        if let handler = routes[key] {
            return handler(request, body, context)
        }
        // Fallback to 404
        return nil
    }
}

// MARK: - HTTP Handler

/// HTTP server handler with routing
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var router: Router
    private var currentRequestHead: HTTPRequestHead?
    private var bodyBuffer: ByteBuffer?
    
    init(router: Router) {
        self.router = router
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let request):
            currentRequestHead = request
            bodyBuffer = context.channel.allocator.buffer(capacity: 0)
            
        case .body(var buffer):
            if var body = bodyBuffer {
                body.writeBuffer(&buffer)
                bodyBuffer = body
            }
            
        case .end:
            guard let request = currentRequestHead else {
                return
            }
            
            // Extract request body as string
            let bodyString: String?
            if let buffer = bodyBuffer {
                bodyString = buffer.getString(at: 0, length: buffer.readableBytes)
            } else {
                bodyString = nil
            }
            
            let (responseHead, body): (HTTPResponseHead, String)
            if let routed = router.handle(request: request, body: bodyString, context: context) {
                (responseHead, body) = routed
            } else {
                // 404 Not Found
                responseHead = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ["Content-Type": "text/plain"]
                )
                body = "404 Not Found: \(request.method) \(request.uri)"
            }
            
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            
            var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
            buffer.writeString(body)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
            
            // Reset for next request
            currentRequestHead = nil
            bodyBuffer = nil
        }
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}

// MARK: - Main Server Setup

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

// Configure router
var router = Router()

// Welcome endpoint
router.addRoute(method: .GET, path: "/") { request, body, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Welcome to Swift Server! You requested \(request.method) \(request.uri)"
    return (head, body)
}

// Hello endpoint
router.addRoute(method: .GET, path: "/hello") { request, body, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Hello, World!"
    return (head, body)
}

// Echo endpoint
router.addRoute(method: .POST, path: "/echo") { request, body, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Echo endpoint (POST) received. Body: \(body ?? "(empty)")"
    return (head, body)
}

// GET /questions endpoint
router.addRoute(method: .GET, path: "/questions") { request, body, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "application/json"]
    )
    
    if let json = encodeJSON(predefinedQuestions) {
        return (head, json)
    } else {
        let errorHead = HTTPResponseHead(
            version: request.version,
            status: .internalServerError,
            headers: ["Content-Type": "text/plain"]
        )
        return (errorHead, "Failed to encode questions")
    }
}

// POST /answers endpoint
router.addRoute(method: .POST, path: "/answers") { request, body, context in
    guard let body = body else {
        let head = HTTPResponseHead(
            version: request.version,
            status: .badRequest,
            headers: ["Content-Type": "text/plain"]
        )
        return (head, "Request body is required")
    }
    
    guard let submission = decodeJSON(body, as: AnswerSubmission.self) else {
        let head = HTTPResponseHead(
            version: request.version,
            status: .badRequest,
            headers: ["Content-Type": "text/plain"]
        )
        return (head, "Invalid JSON format. Expected {\"answers\": [{\"questionId\": 1, \"answer\": \"...\"}]}")
    }
    
    // Validate that question IDs exist
    let validQuestionIds = Set(predefinedQuestions.map { $0.id })
    let invalidAnswers = submission.answers.filter { !validQuestionIds.contains($0.questionId) }
    
    if !invalidAnswers.isEmpty {
        let head = HTTPResponseHead(
            version: request.version,
            status: .badRequest,
            headers: ["Content-Type": "text/plain"]
        )
        return (head, "Invalid question IDs: \(invalidAnswers.map { String($0.questionId) }.joined(separator: ", "))")
    }
    
    // Store answers
    AnswerStore.shared.addAnswers(submission.answers)
    
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "application/json"]
    )
    
    let response = ResponseMessage(
        message: "Answers received successfully",
        receivedCount: submission.answers.count,
        totalAnswersStored: AnswerStore.shared.getAnswerCount()
    )
    
    if let json = encodeJSON(response) {
        return (head, json)
    } else {
        let errorHead = HTTPResponseHead(
            version: request.version,
            status: .internalServerError,
            headers: ["Content-Type": "text/plain"]
        )
        return (errorHead, "Failed to encode response")
    }
}

let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(HTTPHandler(router: router))
        }
    }
    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

defer {
    try! group.syncShutdownGracefully()
}

let host = "127.0.0.1"
let port = 8080

do {
    let channel = try bootstrap.bind(host: host, port: port).wait()
    print("Server started and listening on \(host):\(port)")
    print("Available routes:")
    print("  GET  /          - Welcome message")
    print("  GET  /hello     - Hello World")
    print("  POST /echo      - Echo endpoint")
    print("  GET  /questions - Returns list of survey questions (3-5 items)")
    print("  POST /answers   - Accepts user answers and stores them in memory")
    print("")
    print("Predefined questions loaded: \(predefinedQuestions.count)")
    try channel.closeFuture.wait()
} catch {
    print("Failed to start server: \(error)")
}