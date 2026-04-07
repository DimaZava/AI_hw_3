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
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.root) { request, body, context in
            if let htmlContent = dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.htmlFile)"
            ) {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.htmlHeaders()
                )
                return (head, htmlContent)
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.htmlHeaders()
                )
                let fallbackHTML = ServerConstants.Frontend.fallbackHTML
                return (head, fallbackHTML)
            }
        }
        
        // Serve CSS
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.cssStyle) { request, body, context in
            if let cssContent = dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.cssFile)"
            ) {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.cssHeaders()
                )
                return (head, cssContent)
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, ServerConstants.Errors.cssFileNotFound)
            }
        }
        
        // HEAD route for CSS
        router.addRoute(method: .HEAD, path: ServerConstants.Endpoints.cssStyle) { request, body, context in
            if dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.cssFile)"
            ) != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.cssHeaders()
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, "")
            }
        }
        
        // Serve Design Tokens CSS
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.designTokensCSS) { request, body, context in
            if let cssContent = dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.designTokensCSSFile)"
            ) {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.cssHeaders()
                )
                return (head, cssContent)
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, ServerConstants.Errors.designTokensCSSFileNotFound)
            }
        }
        
        // HEAD route for Design Tokens CSS
        router.addRoute(method: .HEAD, path: ServerConstants.Endpoints.designTokensCSS) { request, body, context in
            if dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.designTokensCSSFile)"
            ) != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.cssHeaders()
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, "")
            }
        }
        
        // Serve JavaScript
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.javascript) { request, body, context in
            if let jsContent = dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.javascriptFile)"
            ) {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.javascriptHeaders()
                )
                return (head, jsContent)
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, ServerConstants.Errors.javascriptFileNotFound)
            }
        }
        
        // HEAD route for JavaScript
        router.addRoute(method: .HEAD, path: ServerConstants.Endpoints.javascript) { request, body, context in
            if dependencies.fileReader.readFileContents(
                "\(ServerConstants.Paths.publicDirectory)/\(ServerConstants.Paths.javascriptFile)"
            ) != nil {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: ServerConstants.HTTP.javascriptHeaders()
                )
                return (head, "")
            } else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .notFound,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, "")
            }
        }
    }
    
    // MARK: - API Routes
    
    private static func configureAPIRoutes(on router: inout Router, dependencies: Dependencies) {
        // Hello endpoint
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.hello) { request, body, context in
            let head = HTTPResponseHead(
                version: request.version,
                status: .ok,
                headers: ServerConstants.HTTP.plainTextHeaders()
            )
            let body = "Hello, World!"
            return (head, body)
        }
        
        // Echo endpoint
        router.addRoute(method: .POST, path: ServerConstants.Endpoints.echo) { request, body, context in
            let head = HTTPResponseHead(
                version: request.version,
                status: .ok,
                headers: ServerConstants.HTTP.plainTextHeaders()
            )
            let body = "Echo endpoint (POST) received. Body: \(body ?? "(empty)")"
            return (head, body)
        }
        
        // GET /questions endpoint
        router.addRoute(method: .GET, path: ServerConstants.Endpoints.questions) { request, body, context in
            let head = HTTPResponseHead(
                version: request.version,
                status: .ok,
                headers: ServerConstants.HTTP.jsonHeaders()
            )
            
            if let json = dependencies.jsonCoder.encode(dependencies.questionProvider.questions) {
                return (head, json)
            } else {
                let errorHead = HTTPResponseHead(
                    version: request.version,
                    status: .internalServerError,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (errorHead, ServerConstants.Errors.encodeQuestionsFailed)
            }
        }
        
        // POST /answers endpoint
        router.addRoute(method: .POST, path: ServerConstants.Endpoints.answers) { request, body, context in
            guard let body = body else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .badRequest,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, ServerConstants.Errors.bodyRequired)
            }
            
            guard let submission = dependencies.jsonCoder.decode(body, as: AnswerSubmission.self) else {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .badRequest,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, ServerConstants.Errors.invalidJSON)
            }
            
            // Validate that question IDs exist
            let validQuestionIds = Set(dependencies.questionProvider.questions.map { $0.id })
            let invalidAnswers = submission.answers.filter { !validQuestionIds.contains($0.questionId) }
            
            if !invalidAnswers.isEmpty {
                let head = HTTPResponseHead(
                    version: request.version,
                    status: .badRequest,
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (head, "\(ServerConstants.Errors.invalidQuestionIDsPrefix)\(invalidAnswers.map { String($0.questionId) }.joined(separator: ", "))")
            }
            
            // Store answers
            dependencies.answerStore.addAnswers(submission.answers)
            
            let head = HTTPResponseHead(
                version: request.version,
                status: .ok,
                headers: ServerConstants.HTTP.jsonHeaders()
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
                    headers: ServerConstants.HTTP.plainTextHeaders()
                )
                return (errorHead, ServerConstants.Errors.encodeFailed)
            }
        }
    }
}