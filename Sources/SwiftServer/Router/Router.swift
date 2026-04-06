import NIO
import NIOHTTP1

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