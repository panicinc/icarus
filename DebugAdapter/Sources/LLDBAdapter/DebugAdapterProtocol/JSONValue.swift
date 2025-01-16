import Foundation

/// A structured wrapper around any valid JSON value.
public enum JSONValue: Sendable {
    case null
    case bool(Bool)
    case string(String)
    case number(Double)
    indirect case array([JSONValue])
    indirect case object([String: JSONValue])
}

extension JSONValue: Hashable {}

extension JSONValue: Codable {
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
        else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        }
        else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        }
        else {
            throw DecodingError.typeMismatch(JSONValue.self, .init(codingPath: container.codingPath, debugDescription: "Could not decode JSON value", underlyingError: nil))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

extension JSONValue {
    public init(_ value: (any Sendable)?) throws {
        switch value {
        case .none:
            self = .null
        case let value as String:
            self = .string(value)
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        case let value as NSNumber:
            // Handle NSNumber values specifically in order to correctly
            // determine if they are booleans or numbers.
            switch CFGetTypeID(value) {
            case CFBooleanGetTypeID():
                self = .bool(CFBooleanGetValue(value))
            default:
                self = .number(Double(truncating: value))
            }
        case is NSNull:
            self = .null
#endif
        case let value as Bool:
            self = .bool(value)
        case let value as Double:
            self = .number(value)
        case let value as any BinaryFloatingPoint:
            self = .number(Double(value))
        case let value as any BinaryInteger:
            self = .number(Double(value))
        case let value as [any Sendable]:
            self = .array(try value.map { try JSONValue($0) })
        case let value as [String: any Sendable]:
            self = .object(try value.mapValues { try JSONValue($0) })
        default:
            throw JSONValueError.invalidValue(value)
        }
    }
}

extension JSONValue {
    public var jsonValue: Any? {
        switch self {
        case .null:
            return nil
        case let .bool(value):
            return value
        case let .string(value):
            return value
        case let .number(value):
            return value
        case let .array(value):
            return value.map { $0.jsonValue }
        case let .object(value):
            return value.mapValues { $0.jsonValue }
        }
    }
    
    public var isNull: Bool {
        guard case .null = self else {
            return false
        }
        return true
    }
    
    public var bool: Bool? {
        guard case let .bool(value) = self else {
            return nil
        }
        return value
    }
    
    public var number: Double? {
        guard case let .number(value) = self else {
            return nil
        }
        return value
    }
    
    public var string: String? {
        guard case let .string(value) = self else {
            return nil
        }
        return value
    }
    
    public subscript(_ key: String) -> JSONValue? {
        guard case let .object(value) = self else {
            return nil
        }
        return value[key]
    }
}

extension JSONValue: ExpressibleByStringInterpolation {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

public enum JSONValueError: LocalizedError {
    case invalidValue(any Sendable)
    
    public var errorDescription: String? {
        switch self {
        case let .invalidValue(value):
            return "Could not coerce value to JSON: \(value)"
        }
    }
}
