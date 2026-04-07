import Foundation

/// Protocol defining the interface for answer storage
protocol AnswerStore {
    func addAnswers(_ answers: [Answer])
    func getAllAnswers() -> [Answer]
    func getAnswerCount() -> Int
}

/// In-memory implementation of answer storage
final class InMemoryAnswerStoreImpl: AnswerStore {
    private var allAnswers: [Answer] = []
    private let lock = NSLock()
    
    func addAnswers(_ answers: [Answer]) {
        lock.lock()
        defer { lock.unlock() }
        allAnswers.append(contentsOf: answers)
    }
    
    func getAllAnswers() -> [Answer] {
        lock.lock()
        defer { lock.unlock() }
        return allAnswers
    }
    
    func getAnswerCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return allAnswers.count
    }
}