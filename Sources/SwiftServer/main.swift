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
- GET  /             - Serves frontend HTML
- GET  /css/style.css - Frontend CSS
- GET  /js/script.js  - Frontend JavaScript
- GET  /health       - Health check
- GET  /questions    - Returns list of survey questions (3-5 items)
- POST /answers      - Accepts user answers and stores them in memory

To test with curl:
$ curl http://127.0.0.1:8080/
$ curl http://127.0.0.1:8080/health
$ curl http://127.0.0.1:8080/questions
$ curl -X POST http://127.0.0.1:8080/answers -H "Content-Type: application/json" -d '{"answers": [{"questionId": 1, "answer": "Yes"}, {"questionId": 2, "answer": "No"}]}'

To stop the server, press Ctrl+C.
*/

import NIO
import NIOHTTP1
import Foundation

// MARK: - Main Entry Point

do {
    try Server.start()
} catch {
    print("Server failed to start: \(error)")
    exit(1)
}