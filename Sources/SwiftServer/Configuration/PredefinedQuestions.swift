import Foundation

/// Configuration containing predefined survey questions
enum SurveyConfiguration {
    
    /// The list of predefined survey questions
    static let questions: [Question] = [
        Question(
            id: 1,
            text: "How satisfied are you with our service?",
            type: "singleChoice",
            options: ["Very satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very dissatisfied"]
        ),
        Question(
            id: 2,
            text: "What is your age group?",
            type: "singleChoice",
            options: ["Under 18", "18-24", "25-34", "35-44", "45-54", "55+"]
        ),
        Question(
            id: 3,
            text: "How did you hear about us?",
            type: "multipleChoice",
            options: ["Social media", "Friend recommendation", "Online advertisement", "Search engine", "Other"]
        ),
        Question(
            id: 4,
            text: "What features would you like to see improved?",
            type: "text",
            options: nil
        ),
        Question(
            id: 5,
            text: "Would you recommend our service to others?",
            type: "singleChoice",
            options: ["Definitely yes", "Probably yes", "Not sure", "Probably not", "Definitely not"]
        )
    ]
}