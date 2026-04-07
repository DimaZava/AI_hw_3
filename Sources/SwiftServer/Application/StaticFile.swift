import NIOHTTP1

/// Represents a static file served by the server.
enum StaticFile: CaseIterable {
    case css
    case designTokensCSS
    case javascript
    
    var endpoint: String {
        switch self {
        case .css: return ServerConstants.Endpoints.cssStyle
        case .designTokensCSS: return ServerConstants.Endpoints.designTokensCSS
        case .javascript: return ServerConstants.Endpoints.javascript
        }
    }
    
    var fileSubpath: String {
        switch self {
        case .css: return ServerConstants.Paths.cssFile
        case .designTokensCSS: return ServerConstants.Paths.designTokensCSSFile
        case .javascript: return ServerConstants.Paths.javascriptFile
        }
    }
    
    var contentTypeHeaders: () -> HTTPHeaders {
        switch self {
        case .css, .designTokensCSS: return ServerConstants.HTTP.cssHeaders
        case .javascript: return ServerConstants.HTTP.javascriptHeaders
        }
    }
    
    var notFoundError: String {
        switch self {
        case .css: return ServerConstants.Errors.cssFileNotFound
        case .designTokensCSS: return ServerConstants.Errors.designTokensCSSFileNotFound
        case .javascript: return ServerConstants.Errors.javascriptFileNotFound
        }
    }
}