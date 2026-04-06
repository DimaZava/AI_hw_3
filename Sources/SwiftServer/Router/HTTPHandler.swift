import NIO
import NIOHTTP1

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