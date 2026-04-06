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
- GET  /      - Welcome message
- GET  /hello - Hello World
- POST /echo  - Echo endpoint

To test with curl:
$ curl http://127.0.0.1:8080/
$ curl http://127.0.0.1:8080/hello
$ curl -X POST http://127.0.0.1:8080/echo

To stop the server, press Ctrl+C.
*/

import NIO
import NIOHTTP1

/// Simple router that maps (method, path) to a handler
struct Router {
    typealias Handler = (HTTPRequestHead, ChannelHandlerContext) -> (HTTPResponseHead, String)

    private var routes: [String: Handler] = [:]

    mutating func addRoute(method: HTTPMethod, path: String, handler: @escaping Handler) {
        let key = "\(method) \(path)"
        routes[key] = handler
    }

    func handle(request: HTTPRequestHead, context: ChannelHandlerContext) -> (HTTPResponseHead, String)? {
        let key = "\(request.method) \(request.uri)"
        if let handler = routes[key] {
            return handler(request, context)
        }
        // Fallback to 404
        return nil
    }
}

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

            let (responseHead, body): (HTTPResponseHead, String)
            if let routed = router.handle(request: request, context: context) {
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

/// Main server setup
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

// Configure router
var router = Router()
router.addRoute(method: .GET, path: "/") { request, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Welcome to Swift Server! You requested \(request.method) \(request.uri)"
    return (head, body)
}

router.addRoute(method: .GET, path: "/hello") { request, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Hello, World!"
    return (head, body)
}

router.addRoute(method: .POST, path: "/echo") { request, context in
    let head = HTTPResponseHead(
        version: request.version,
        status: .ok,
        headers: ["Content-Type": "text/plain"]
    )
    let body = "Echo endpoint (POST) received"
    return (head, body)
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
    print("  GET  /      - Welcome message")
    print("  GET  /hello - Hello World")
    print("  POST /echo  - Echo endpoint")
    try channel.closeFuture.wait()
} catch {
    print("Failed to start server: \(error)")
}