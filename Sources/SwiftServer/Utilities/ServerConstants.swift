import Foundation

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
    
    // MARK: - Question Configuration
    
    /// Question-related constants
    enum Questions {
        /// Minimum question ID
        static let minQuestionId: Int = 1
        /// Maximum question ID (based on predefined questions)
        static let maxQuestionId: Int = 5
    }
    
    // MARK: - HTTP Configuration
    
    /// HTTP-related constants
    enum HTTP {
        /// Default HTTP response headers
        static let defaultHeaders: [String: String] = [
            "Content-Type": "text/plain"
        ]
        
        /// JSON content type header
        static let jsonContentType = "application/json"
        
        /// HTML content type header
        static let htmlContentType = "text/html"
        
        /// CSS content type header
        static let cssContentType = "text/css"
        
        /// JavaScript content type header
        static let javascriptContentType = "application/javascript"
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
        
        /// JavaScript file path
        static let javascriptFile = "js/script.js"
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
        
        /// File not found error
        static let fileNotFound = "File not found"
    }
}