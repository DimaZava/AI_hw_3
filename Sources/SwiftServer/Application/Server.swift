import NIO
import NIOHTTP1

/// Server setup and management
enum Server {
    
    /// Starts the HTTP server on the specified host and port
    /// - Parameters:
    ///   - host: The host address to bind to (default: 127.0.0.1)
    ///   - port: The port to bind to (default: 8080)
    ///   - dependencies: The dependencies to use for the server (default: production dependencies)
    static func start(
        host: String = ServerConstants.Server.defaultHost,
        port: Int = ServerConstants.Server.defaultPort,
        dependencies: Dependencies = Dependencies.defaultDependencies()
    ) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        // Configure router with all routes
        var router = Router()
        Routes.configureRoutes(on: &router, dependencies: dependencies)
        
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
            printServerStartupInfo(host: host, port: port, dependencies: dependencies)
            try channel.closeFuture.wait()
        } catch {
            print("Failed to start server: \(error)")
            throw error
        }
    }
    
    /// Prints server startup information
    private static func printServerStartupInfo(host: String, port: Int, dependencies: Dependencies) {
        print("Server started and listening on \(host):\(port)")
        print("Available routes:")
        print("  GET  /             - Serves frontend HTML")
        print("  GET  /css/style.css - Frontend CSS")
        print("  GET  /js/script.js  - Frontend JavaScript")
        print("  GET  /health       - Health check")
        print("  GET  /questions    - Returns list of survey questions (\(dependencies.questionProvider.questions.count) items)")
        print("  POST /answers      - Accepts user answers and stores them in memory")
        print("")
        print("Frontend available at: http://\(host):\(port)/")
    }
}