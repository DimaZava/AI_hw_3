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
- GET  /             - Serves frontend HTML
- GET  /style.css    - Frontend CSS
- GET  /script.js    - Frontend JavaScript
- GET  /hello        - Hello World
- POST /echo         - Echo endpoint
- GET  /questions    - Returns list of survey questions (3-5 items)
- POST /answers      - Accepts user answers and stores them in memory

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

// MARK: - Main Server Setup

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

// Configure router
var router = Router()

// Helper function to read file contents
func readFileContents(_ path: String) -> String? {
    let fileManager = FileManager.default
    let currentDirectory = fileManager.currentDirectoryPath
    let fullPath = currentDirectory + "/" + path
    
    guard fileManager.fileExists(atPath: fullPath),
          let data = fileManager.contents(atPath: fullPath),
          let content = String(data: data, encoding: .utf8) else {
        return nil
    }
    
    return content
}

// Serve frontend HTML
router.addRoute(method: .GET, path: "/") { request, body, context in
    if let htmlContent = readFileContents("public/index.html") {
        let head = HTTPResponseHead(
            version: request.version,
            status: .ok,
            headers: ["Content-Type": "text/html"]
        )
        return (head, htmlContent)
    } else {
        let head = HTTPResponseHead(
            version: request.version,
            status: .ok,
            headers: ["Content-Type": "text/html"]
        )
        let fallbackHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Survey Application</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 40px; text-align: center; }
                h1 { color: #333; }
                p { color: #666; }
                a { color: #4b6cb7; text-decoration: none; }
            </style>
        </head>
        <body>
            <h1>Survey Application</h1>
            <p>Frontend files not found. Please ensure the server is running from the correct directory.</p>
            <p>Available API endpoints:</p>
            <ul style="list-style: none; padding: 0;">
                <li><a href="/questions">GET /questions</a> - Get survey questions</li>
                <li><a href="/hello">GET /hello</a> - Hello endpoint</li>
            </ul>
        </body>
        </html>
        """
        return (head, fallbackHTML)
    }
}

// Serve CSS
router.addRoute(method: .GET, path: "/css/style.css") { request, body, context in
    if let cssContent = readFileContents("public/css/style.css") {
        let head = HTTPResponseHead(
            version: request.version,
            status: .ok,
            headers: ["Content-Type": "text/css"]
        )
        return (head, cssContent)
    } else {
        let head = HTTPResponseHead(
            version: request.version,
            status: .notFound,
            headers: ["Content-Type": "text/plain"]
        )
        return (head, "CSS file not found")
    }
}

// Serve JavaScript
router.addRoute(method: .GET, path: "/js/script.js") { request, body, context in
    if let jsContent = readFileContents("public/js/script.js") {
        let head = HTTPResponseHead(
            version: request.version,
            status: .ok,
            headers: ["Content-Type": "application/javascript"]
        )
        return (head, jsContent)
    } else {
        let head = HTTPResponseHead(
            version: request.version,
            status: .notFound,
            headers: ["Content-Type": "text/plain"]
        )
        return (head, "JavaScript file not found")
    }
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
    print("  GET  /             - Serves frontend HTML")
    print("  GET  /style.css    - Frontend CSS")
    print("  GET  /script.js    - Frontend JavaScript")
    print("  GET  /hello        - Hello World")
    print("  POST /echo         - Echo endpoint")
    print("  GET  /questions    - Returns list of survey questions (3-5 items)")
    print("  POST /answers      - Accepts user answers and stores them in memory")
    print("")
    print("Predefined questions loaded: \(predefinedQuestions.count)")
    print("Frontend available at: http://\(host):\(port)/")
    try channel.closeFuture.wait()
} catch {
    print("Failed to start server: \(error)")
}