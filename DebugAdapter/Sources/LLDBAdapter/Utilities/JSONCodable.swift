import Foundation

/// An arbitrary JSON-compatible value that is codable
@dynamicMemberLookup
public enum JSONCodable: Codable {
    case null
    case bool(Bool)
    case string(String)
    case number(Double)
    indirect case array([JSONCodable])
    indirect case object([String: JSONCodable])
    
    public enum JSONValueError: Error {
        case invalidJSONValue
    }
    
    public init(withJSONValue value: Any?) throws {
        if value == nil || value is NSNull {
            self = .null
        }
        else if let value = value as? Bool {
            self = .bool(value)
        }
        else if let value = value as? String {
            self = .string(value)
        }
        else if let value = value as? Double {
            self = .number(value)
        }
        else if let value = value as? Int {
            self = .number(Double(value))
        }
        else if let value = value as? Float {
            self = .number(Double(value))
        }
        else if let value = value as? CGFloat {
            self = .number(Double(value))
        }
        else if let value = value as? NSNumber {
            self = .number(Double(truncating: value))
        }
        else if let value = value as? [Any] {
            let array = try value.map { i in
                return try JSONCodable(withJSONValue: i)
            }
            self = .array(array)
        }
        else if let value = value as? [String: Any] {
            let object = try value.mapValues { i in
                return try JSONCodable(withJSONValue: i)
            }
            self = .object(object)
        }
        else {
            throw JSONValueError.invalidJSONValue
        }
    }
    
    public var JSONValue: Any? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .array(let value):
            return value.map { $0.JSONValue ?? NSNull() }
        case .object(let value):
            return value.mapValues { $0.JSONValue ?? NSNull() }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        }
        else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        }
        else if let value = try? container.decode(String.self) {
            self = .string(value)
        }
        else if let value = try? container.decode(Double.self) {
            self = .number(value)
        }
        else if let value = try? container.decode([JSONCodable].self) {
            self = .array(value)
        }
        else if let value = try? container.decode([String: JSONCodable].self) {
            self = .object(value)
        }
        else {
            throw DecodingError.typeMismatch(JSONCodable.self, .init(codingPath: container.codingPath, debugDescription: "Could not decode JSON value", underlyingError: nil))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
    
    public subscript(dynamicMember member: String) -> JSONCodable? {
        switch self {
        case .object(let value):
            return value[member]
        default:
            return nil
        }
    }
}

extension JSONCodable: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSONCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSONCodable: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension JSONCodable: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(value)
    }
}

extension JSONCodable: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = JSONCodable
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self = .array(elements)
    }
}

extension JSONCodable: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = JSONCodable
    
    public init(dictionaryLiteral elements: (String, JSONCodable)...) {
        let dictionary = Dictionary(uniqueKeysWithValues: elements)
        self = .object(dictionary)
    }
}
