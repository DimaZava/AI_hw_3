import Foundation

/// Utility functions for file operations
enum FileUtilities {
    
    /// Reads the contents of a file at the given path relative to the current working directory
    /// - Parameter path: The file path relative to the current working directory
    /// - Returns: The file contents as a string, or nil if the file doesn't exist or can't be read
    static func readFileContents(_ path: String) -> String? {
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