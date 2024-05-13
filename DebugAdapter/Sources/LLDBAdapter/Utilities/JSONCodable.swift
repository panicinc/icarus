import Foundation
import CoreFoundation

/// A codable JSON value.
public enum JSONCodable {
    case null
    case bool(Bool)
    case string(String)
    case number(Double)
    indirect case array([JSONCodable])
    indirect case object([String: JSONCodable])
    
    public init(_ value: Any?) throws {
        switch value {
        case .none, is NSNull:
            self = .null
        case let value as String:
            self = .string(value)
        case is NSNumber:
            // Note: Do not use `let value as NSNumber` here,
            // as it will coerce Swift's Bool and numeric types.
            let num = value as! NSNumber
            switch CFGetTypeID(num as CFTypeRef) {
            case CFBooleanGetTypeID():
                self = .bool(num.boolValue)
            default:
                self = .number(num.doubleValue)
            }
        case let value as Bool:
            self = .bool(value)
        case let value as Double:
            self = .number(value)
        case let value as any BinaryFloatingPoint:
            self = .number(Double(value))
        case let value as any BinaryInteger:
            self = .number(Double(value))
        case let value as [Any]:
            self = .array(try value.map { try JSONCodable($0) })
        case let value as [String: Any]:
            self = .object(try value.mapValues { try JSONCodable($0) })
        default:
            throw JSONCodableError.invalidValue(value!)
        }
    }
}

extension JSONCodable: Codable {
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

extension JSONCodable {
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
        if case .null = self {
            return true
        }
        else {
            return false
        }
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
    
    public subscript(_ key: String) -> JSONCodable? {
        guard case let .object(value) = self else {
            return nil
        }
        return value[key]
    }
}

extension JSONCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSONCodable: ExpressibleByStringInterpolation {
}

extension JSONCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JSONCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSONCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONCodable...) {
        self = .array(elements)
    }
}

extension JSONCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONCodable)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

public enum JSONCodableError: LocalizedError {
    case invalidValue(Any)
    
    public var errorDescription: String? {
        switch self {
        case .invalidValue(let value):
            return "Could not coerce value to JSON: \(value)"
        }
    }
}
