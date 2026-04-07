import NIO
import NIOHTTP1

/// Server setup and management
enum Server {
    
    /// Starts the HTTP server on the specified host and port
    /// - Parameters:
    ///   - host: The host address to bind to (default: 127.0.0.1)
    ///   - port: The port to bind to (default: 8080)
    static func start(host: String = ServerConstants.Server.defaultHost, port: Int = ServerConstants.Server.defaultPort) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        // Configure router with all routes
        var router = Router()
        Routes.configureRoutes(on: &router)
        
        // Configure server bootstrap
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: ServerConstants.Server.backlogSize)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(router: router))
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: ServerConstants.Server.maxMessagesPerRead)
        
        do {
            let channel = try bootstrap.bind(host: host, port: port).wait()
            printServerStartupInfo(host: host, port: port)
            try channel.closeFuture.wait()
        } catch {
            print("Failed to start server: \(error)")
            throw error
        }
    }
    
    /// Prints server startup information
    private static func printServerStartupInfo(host: String, port: Int) {
        print("Server started and listening on \(host):\(port)")
        print("Available routes:")
        print("  GET  /             - Serves frontend HTML")
        print("  GET  /css/style.css - Frontend CSS")
        print("  GET  /js/script.js  - Frontend JavaScript")
        print("  GET  /hello        - Hello World")
        print("  POST /echo         - Echo endpoint")
        print("  GET  /questions    - Returns list of survey questions (\(SurveyConfiguration.questions.count) items)")
        print("  POST /answers      - Accepts user answers and stores them in memory")
        print("")
        print("Predefined questions loaded: \(SurveyConfiguration.questions.count)")
        print("Frontend available at: http://\(host):\(port)/")
    }
}