import Foundation
import NIOHTTP1

/// Server configuration constants
enum ServerConstants {
    
    // MARK: - Server Configuration
    
    /// Server configuration constants
    enum Server {
        /// Default server port
        static let defaultPort: Int = 8080
        /// Default server host
        static let defaultHost: String = "127.0.0.1"
        /// Server backlog size (Int32 for NIO compatibility)
        static let backlogSize: Int32 = 256
        /// Maximum messages per read (UInt for NIO compatibility)
        static let maxMessagesPerRead: UInt = 1
    }
    
    
    // MARK: - HTTP Configuration
    
    /// HTTP-related constants
    enum HTTP {
        /// JSON content type header
        static let jsonContentType = "application/json"
        
        /// HTML content type header
        static let htmlContentType = "text/html"
        
        /// CSS content type header
        static let cssContentType = "text/css"
        
        /// JavaScript content type header
        static let javascriptContentType = "application/javascript"
        
        /// Creates headers for HTML content
        static func htmlHeaders() -> HTTPHeaders {
            return HTTPHeaders([("Content-Type", htmlContentType)])
        }
        
        /// Creates headers for CSS content
        static func cssHeaders() -> HTTPHeaders {
            return HTTPHeaders([("Content-Type", cssContentType)])
        }
        
        /// Creates headers for JavaScript content
        static func javascriptHeaders() -> HTTPHeaders {
            return HTTPHeaders([("Content-Type", javascriptContentType)])
        }
        
        /// Creates headers for JSON content
        static func jsonHeaders() -> HTTPHeaders {
            return HTTPHeaders([("Content-Type", jsonContentType)])
        }
        
        /// Creates headers for plain text content
        static func plainTextHeaders() -> HTTPHeaders {
            return HTTPHeaders([("Content-Type", "text/plain")])
        }
    }
    
    // MARK: - File Paths
    
    /// File path constants
    enum Paths {
        /// Public directory path
        static let publicDirectory = "public"
        
        /// HTML file path
        static let htmlFile = "index.html"
        
        /// CSS file path
        static let cssFile = "css/style.css"
        
        /// Design tokens CSS file path
        static let designTokensCSSFile = "css/design-tokens.css"
        
        /// JavaScript file path
        static let javascriptFile = "js/script.js"
    }
    
    // MARK: - Endpoints
    
    /// API endpoint path constants
    enum Endpoints {
        /// Root endpoint
        static let root = "/"
        
        /// CSS style endpoint
        static let cssStyle = "/css/style.css"
        
        /// Design tokens CSS endpoint
        static let designTokensCSS = "/css/design-tokens.css"
        
        /// JavaScript endpoint
        static let javascript = "/js/script.js"
        
        /// Health check endpoint
        static let health = "/health"
        
        /// Questions endpoint
        static let questions = "/questions"
        
        /// Answers endpoint
        static let answers = "/answers"
    }
    
    // MARK: - Frontend
    
    /// Frontend HTML constants
    enum Frontend {
        /// Fallback HTML page when index.html is not found
        static let fallbackHTML = """
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
    }
    
    // MARK: - Error Messages
    
    /// Error message constants
    enum Errors {
        /// Invalid JSON format error
        static let invalidJSON = "Invalid JSON format. Expected {\"answers\": [{\"questionId\": 1, \"answer\": \"...\"}]}"
        
        /// Request body required error
        static let bodyRequired = "Request body is required"
        
        /// Failed to encode error
        static let encodeFailed = "Failed to encode response"
        
        /// Failed to encode questions error
        static let encodeQuestionsFailed = "Failed to encode questions"
        
        /// CSS file not found error
        static let cssFileNotFound = "CSS file not found"
        
        /// Design tokens CSS file not found error
        static let designTokensCSSFileNotFound = "Design tokens CSS file not found"
        
        /// JavaScript file not found error
        static let javascriptFileNotFound = "JavaScript file not found"
        
        /// Invalid question IDs error prefix
        static let invalidQuestionIDsPrefix = "Invalid question IDs: "
    }
}