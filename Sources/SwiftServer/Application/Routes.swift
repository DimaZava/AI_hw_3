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
        
        // Define static file routes
        let staticFiles = [
            (path: ServerConstants.Endpoints.cssStyle,
             fileSubpath: ServerConstants.Paths.cssFile,
             contentTypeHeaders: ServerConstants.HTTP.cssHeaders,
             notFoundError: ServerConstants.Errors.cssFileNotFound),
            (path: ServerConstants.Endpoints.designTokensCSS,
             fileSubpath: ServerConstants.Paths.designTokensCSSFile,
             contentTypeHeaders: ServerConstants.HTTP.cssHeaders,
             notFoundError: ServerConstants.Errors.designTokensCSSFileNotFound),
            (path: ServerConstants.Endpoints.javascript,
             fileSubpath: ServerConstants.Paths.javascriptFile,
             contentTypeHeaders: ServerConstants.HTTP.javascriptHeaders,
             notFoundError: ServerConstants.Errors.javascriptFileNotFound)
        ]
        
        for (endpoint, fileSubpath, contentTypeHeaders, notFoundError) in staticFiles {
            // GET handler
            router.addRoute(method: .GET, path: endpoint) { request, body, context in
                let fullPath = "\(ServerConstants.Paths.publicDirectory)/\(fileSubpath)"
                if let content = dependencies.fileReader.readFileContents(fullPath) {
                    let head = HTTPResponseHead(
                        version: request.version,
                        status: .ok,
                        headers: contentTypeHeaders()
                    )
                    return (head, content)
                } else {
                    let head = HTTPResponseHead(
                        version: request.version,
                        status: .notFound,
                        headers: ServerConstants.HTTP.plainTextHeaders()
                    )
                    return (head, notFoundError)
                }
            }
            
            // HEAD handler
            router.addRoute(method: .HEAD, path: endpoint) { request, body, context in
                let fullPath = "\(ServerConstants.Paths.publicDirectory)/\(fileSubpath)"
                if dependencies.fileReader.readFileContents(fullPath) != nil {
                    let head = HTTPResponseHead(
                        version: request.version,
                        status: .ok,
                        headers: contentTypeHeaders()
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