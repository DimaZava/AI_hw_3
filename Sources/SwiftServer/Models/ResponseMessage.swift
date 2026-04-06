import Foundation

struct ResponseMessage: Codable {
    let message: String
    let receivedCount: Int
    let totalAnswersStored: Int
}