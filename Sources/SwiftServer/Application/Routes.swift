import NIO
import NIOHTTP1
import Foundation

/// Route definitions for the HTTP server
enum Routes {
    
    /// Configures all routes on the given router with dependencies
    /// - Parameters:
    ///   - router: The router to configure with routes
    ///   - dependencies: The dependencies to use for route handlers
    static func configureRoutes(on router: inout Router, dependencies: Dependencies) {
        configureFrontendRoutes(on: &router, dependencies: dependencies)
        configureAPIRoutes(on: &router, dependencies: dependencies)
    }
    
    // MARK: - Frontend Routes
    
    private static func configureFrontendRoutes(on router: inout Router, dependencies: Dependencies) {
        // Serve frontend HTML
        router.addRoute(method: .GET, path: "/") { request, body, context in
            if let htmlContent = dependencies.fileReader.readFileContents("public/index.html") {
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
                let fallbackHTML = ServerConstants.Frontend.fallbackHTML
                return (head, fallbackHTML)
            }
        }
        
        // Serve CSS
        router.addRoute(method: .GET, path: "/css/style.css") { request, body, context in
            if let cssContent = dependencies.fileReader.readFileContents("public/css/style.css") {
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
        
        // HEAD route for CSS
        router.addRoute(method: .HEAD, path: "/css/style.css") { request, body, context in
            if dependencies.fileReader.readFileContents("public/css/style.css") != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ["Content-Type": "text/css"]
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ["Content-Type": "text/plain"]
                )
                return (head, "")
            }
        }
        
        // Serve Design Tokens CSS
        router.addRoute(method: .GET, path: "/css/design-tokens.css") { request, body, context in
            if let cssContent = dependencies.fileReader.readFileContents("public/css/design-tokens.css") {
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
                return (head, "Design tokens CSS file not found")
            }
        }
        
        // HEAD route for Design Tokens CSS
        router.addRoute(method: .HEAD, path: "/css/design-tokens.css") { request, body, context in
            if dependencies.fileReader.readFileContents("public/css/design-tokens.css") != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ["Content-Type": "text/css"]
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ["Content-Type": "text/plain"]
                )
                return (head, "")
            }
        }
        
        // Serve JavaScript
        router.addRoute(method: .GET, path: "/js/script.js") { request, body, context in
            if let jsContent = dependencies.fileReader.readFileContents("public/js/script.js") {
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
        
        // HEAD route for JavaScript
        router.addRoute(method: .HEAD, path: "/js/script.js") { request, body, context in
            if dependencies.fileReader.readFileContents("public/js/script.js") != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ["Content-Type": "application/javascript"]
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ["Content-Type": "text/plain"]
                )
                return (head, "")
            }
        }
    }
    
    // MARK: - API Routes
    
    private static func configureAPIRoutes(on router: inout Router, dependencies: Dependencies) {
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
            
            if let json = dependencies.jsonCoder.encode(dependencies.questionProvider.questions) {
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
            
            guard let submission = dependencies.jsonCoder.decode(body, as: AnswerSubmission.self) else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .badRequest,
                    headers: ["Content-Type": "text/plain"]
                )
                return (head, "Invalid JSON format. Expected {\"answers\": [{\"questionId\": 1, \"answer\": \"...\"}]}")
            }
            
            // Validate that question IDs exist
            let validQuestionIds = Set(dependencies.questionProvider.questions.map { $0.id })
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
            dependencies.answerStore.addAnswers(submission.answers)
            
            let head = HTTPResponseHead(
                version: request.version,
                status: .ok,
                headers: ["Content-Type": "application/json"]
            )
            
            let response = ResponseMessage(
                message: "Answers received successfully",
                receivedCount: submission.answers.count,
                totalAnswersStored: dependencies.answerStore.getAnswerCount()
            )
            
            if let json = dependencies.jsonCoder.encode(response) {
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
    }
}