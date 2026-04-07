import Foundation

/// Container for all dependencies used by the server
struct Dependencies {
    let answerStore: AnswerStore
    let questionProvider: QuestionProvider
    let fileReader: FileReader
    let jsonCoder: JSONCoder
    
    /// Creates default dependencies for production
    static func defaultDependencies() -> Dependencies {
        Dependencies(
            answerStore: InMemoryAnswerStoreImpl(),
            questionProvider: PredefinedQuestionProviderImpl(),
            fileReader: LocalFileReaderImpl(),
            jsonCoder: FoundationJSONCoderImpl()
        )
    }
}