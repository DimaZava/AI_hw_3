import Foundation

struct Question: Codable {
    let id: Int
    let text: String
    let type: String  // "text", "singleChoice", "multipleChoice"
    let options: [String]?
}