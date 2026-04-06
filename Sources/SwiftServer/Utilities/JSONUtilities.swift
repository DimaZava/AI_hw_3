import Foundation

func encodeJSON<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}

func decodeJSON<T: Decodable>(_ string: String, as type: T.Type) -> T? {
    guard let data = string.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
}