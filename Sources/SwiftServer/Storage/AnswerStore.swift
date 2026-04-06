import Foundation

class AnswerStore {
    static let shared = AnswerStore()
    private init() {}
    
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