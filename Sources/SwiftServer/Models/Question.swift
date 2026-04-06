import Foundation

struct Question: Codable {
    let id: Int
    let text: String
    let type: String  // "text", "singleChoice", "multipleChoice"
    let options: [String]?
    
    // Computed property for human-readable type
    var readableType: String {
        switch type {
        case "singleChoice":
            return "Single choice"
        case "multipleChoice":
            return "Multiple choice"
        case "text":
            return "Text answer"
        default:
            return type.capitalized
        }
    }
    
    // Custom coding keys to include readableType in encoded output
    enum CodingKeys: String, CodingKey {
        case id, text, type, options, readableType
    }
    
    // Memberwise initializer (needed because we have custom encode/decode)
    init(id: Int, text: String, type: String, options: [String]?) {
        self.id = id
        self.text = text
        self.type = type
        self.options = options
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encode(readableType, forKey: .readableType)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        type = try container.decode(String.self, forKey: .type)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        // readableType is computed, so we don't need to decode it
    }
}