import Foundation

/// Protocol for reading file contents
protocol FileReader {
    func readFileContents(_ path: String) -> String?
}

/// Local file system reader
struct LocalFileReaderImpl: FileReader {
    func readFileContents(_ path: String) -> String? {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let fullPath = currentDirectory + "/" + path
        
        guard fileManager.fileExists(atPath: fullPath),
              let data = fileManager.contents(atPath: fullPath),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return content
    }
}