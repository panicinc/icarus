import Foundation

// These types are up-to-date as of Debug Adapter Protocol v1.70.
// https://microsoft.github.io/debug-adapter-protocol/changelog

public protocol DebugAdapterRequest: Sendable, Codable {
    associatedtype Result: Sendable
    static var command: String { get }
    
    /// Invoked if a request is decoded with an empty arguments value.
    /// Requests can implement this method to ensure an "empty" request is created in such cases.
    /// By default, a protocol extension implements this and throws DebugAdapterRequestError.emptyArgumentsNotAllowed.
    init() throws
}

/// Marking a request with this protocol indicates its result is non-optional.
public protocol DebugAdapterRequestWithRequiredResult: DebugAdapterRequest where Result: Codable {
}

/// Marking a request with this protocol indicates its result is optional.
/// This is done instead of providing an Optional result type to ensure
/// that the optional value can be enforced during runtime decoding.
public protocol DebugAdapterRequestWithOptionalResult: DebugAdapterRequest where Result: Codable {
}

public enum DebugAdapterRequestError: Error, Sendable {
    case emptyArgumentsNotAllowed
}

public extension DebugAdapterRequest {
    init() throws {
        throw DebugAdapterRequestError.emptyArgumentsNotAllowed
    }
}

public protocol DebugAdapterEvent: Sendable, Codable {
    static var event: String { get }
    
    /// Invoked if an event is decoded with an empty body value.
    /// Events can implement this method to ensure an "empty" event is created in such cases.
    /// By default, a protocol extension implements this and throws DebugAdapterEventError.emptyBodyNotAllowed.
    init() throws
}

public enum DebugAdapterEventError: Error, Sendable {
    case emptyBodyNotAllowed
}

public extension DebugAdapterEvent {
    init() throws {
        throw DebugAdapterEventError.emptyBodyNotAllowed
    }
}

public enum DebugAdapter {
    public struct Capabilities: Sendable, Codable {
        public var supportsConfigurationDoneRequest: Bool?
        public var supportsFunctionBreakpoints: Bool?
        public var supportsConditionalBreakpoints: Bool?
        public var supportsHitConditionalBreakpoints: Bool?
        public var supportsEvaluateForHovers: Bool?
        public var exceptionBreakpointFilters: [ExceptionBreakpointFilter]?
        public var supportsStepBack: Bool?
        public var supportsSetVariable: Bool?
        public var supportsRestartFrame: Bool?
        public var supportsGotoTargetsRequest: Bool?
        public var supportsStepInTargetsRequest: Bool?
        public var supportsCompletionsRequest: Bool?
        public var completionTriggerCharacters: [String]?
        public var supportsModulesRequest: Bool?
        public var additionalModuleColumns: [ColumnDescriptor]?
        public var supportedChecksumAlgorithms: [Checksum.Algorithm]?
        public var supportsRestartRequest: Bool?
        public var supportsExceptionOptions: Bool?
        public var supportsValueFormattingOptions: Bool?
        public var supportsExceptionInfoRequest: Bool?
        public var supportTerminateDebuggee: Bool?
        public var supportSuspendDebuggee: Bool?
        public var supportsDelayedStackTraceLoading: Bool?
        public var supportsLoadedSourcesRequest: Bool?
        public var supportsLogPoints: Bool?
        public var supportsTerminateThreadsRequest: Bool?
        public var supportsSetExpression: Bool?
        public var supportsTerminateRequest: Bool?
        public var supportsDataBreakpoints: Bool?
        public var supportsReadMemoryRequest: Bool?
        public var supportsWriteMemoryRequest: Bool?
        public var supportsDisassembleRequest: Bool?
        public var supportsCancelRequest: Bool?
        public var supportsBreakpointLocationsRequest: Bool?
        public var supportsClipboardContext: Bool?
        public var supportsSteppingGranularity: Bool?
        public var supportsInstructionBreakpoints: Bool?
        public var supportsExceptionFilterOptions: Bool?
        public var supportsSingleThreadExecutionRequests: Bool?
        public var supportsDataBreakpointBytes: Bool?
        public var breakpointModes: [BreakpointMode]?
        public var supportsANSIStyling: Bool?
        
        public init() {}
    }
    
    public struct Breakpoint: Sendable, Hashable, Codable {
        public var id: Int?
        public var verified: Bool
        public var message: String?
        public var source: Source?
        public var line: Int?
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        public var instructionReference: String?
        public var offset: Int?
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let pending: Reason = "pending"
            public static let failed: Reason = "failed"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason?
        
        public init(id: Int? = nil, verified: Bool = false, message: String? = nil, reason: Reason? = nil) {
            self.id = id
            self.verified = verified
            self.message = message
            self.reason = reason
        }
    }
    
    public struct BreakpointLocation: Sendable, Hashable, Codable {
        public var line: Int
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        
        public init(line: Int) {
            self.line = line
        }
    }
    
    public struct BreakpointMode: Sendable, Hashable, Codable {
        public var mode: String
        public var label: String
        public var description: String?
        
        public struct Applicability: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let source: Applicability = "source"
            public static let exception: Applicability = "exception"
            public static let data: Applicability = "data"
            public static let instruction: Applicability = "instruction"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var appliesTo: [Applicability]
        
        public init(mode: String, label: String, appliesTo: [Applicability]) {
            self.mode = mode
            self.label = label
            self.appliesTo = appliesTo
        }
    }
    
    public struct Checksum: Sendable, Hashable, Codable {
        public struct Algorithm: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public static let md5: Algorithm = "MD5"
            public static let sha1: Algorithm = "SHA1"
            public static let sha256: Algorithm = "SHA256"
            public static let timestamp: Algorithm = "timestamp"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var algorithm: Algorithm
        public var checksum: String
        
        public init(algorithm: Algorithm, checksum: String) {
            self.algorithm = algorithm
            self.checksum = checksum
        }
    }
    
    public struct ColumnDescriptor: Sendable, Hashable, Codable {
        public var attributeName: String
        public var label: String
        public var format: String?
        
        public enum ColumnType: String, Sendable, Hashable, Codable {
            case string
            case number
            case boolean
            case unixTimestampUTC
        }
        public var type: ColumnType?
        
        public var width: Double?
        
        public init(attributeName: String, label: String) {
            self.attributeName = attributeName
            self.label = label
        }
    }
    
    public struct CompletionItem: Sendable, Hashable, Codable {
        public var label: String
        public var text: String?
        public var sortText: String?
        public var detail: String?
        
        public struct Kind: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let method: Kind = "kind"
            public static let function: Kind = "function"
            public static let constructor: Kind = "constructor"
            public static let variable: Kind = "variable"
            public static let `class`: Kind = "class"
            public static let interface: Kind = "interface"
            public static let module: Kind = "module"
            public static let property: Kind = "property"
            public static let unit: Kind = "unit"
            public static let value: Kind = "value"
            public static let `enum`: Kind = "enum"
            public static let keyword: Kind = "keyword"
            public static let snippet: Kind = "snippet"
            public static let text: Kind = "text"
            public static let color: Kind = "color"
            public static let file: Kind = "file"
            public static let reference: Kind = "reference"
            public static let customcolor: Kind = "customcolor"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var type: Kind?
        
        public var start: Int?
        public var length: Int?
        public var selectionStart: Int?
        public var selectionLength: Int?
        
        public init(label: String) {
            self.label = label
        }
    }
    
    public struct DataBreakpoint: Sendable, Hashable, Codable {
        public var dataId: String
        
        public struct AccessType: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public static let read: AccessType = "read"
            public static let write: AccessType = "write"
            public static let readWrite: AccessType = "readWrite"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var accessType: AccessType?
        
        public var condition: String?
        public var hitCondition: String?
        
        public init(dataId: String, accessType: AccessType? = nil) {
            self.dataId = dataId
            self.accessType = accessType
        }
    }
    
    public struct DisassembledInstruction: Sendable, Hashable, Codable {
        public var address: String
        public var instruction: String
        public var instructionBytes: String?
        public var symbol: String?
        public var location: Source?
        public var line: Int?
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        
        public struct PresentationHint: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let normal: PresentationHint = "normal"
            public static let invalid: PresentationHint = "invalid"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var presentationHint: PresentationHint?
        
        public init(address: String, instruction: String) {
            self.address = address
            self.instruction = instruction
        }
    }
    
    public struct ExceptionBreakpointFilter: Sendable, Hashable, Codable {
        public var filter: String
        public var label: String
        public var description: String?
        public var `default`: Bool?
        public var supportsCondition: Bool?
        public var conditionDescription: String?
        
        public init(filter: String, label: String, description: String? = nil, default: Bool? = nil) {
            self.filter = filter
            self.label = label
            self.description = description
            self.default = `default`
        }
    }
    
    public struct ExceptionBreakMode: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
        public static let never: ExceptionBreakMode = "never"
        public static let always: ExceptionBreakMode = "always"
        public static let unhandled: ExceptionBreakMode = "unhandled"
        public static let userUnhandled: ExceptionBreakMode = "userUnhandled"
        
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: StringLiteralType) {
            self.rawValue = value
        }
    }
    
    public struct ExceptionDetails: Sendable, Hashable, Codable {
        public var message: String?
        public var typeName: String?
        public var fullTypeName: String?
        public var evaluateName: String?
        public var stackTrace: String?
        public var innerException: [ExceptionDetails]?
        
        public init() {}
    }
    
    public struct ExceptionFilterOptions: Sendable, Hashable, Codable {
        public var filterId: String
        public var condition: String?
        public var mode: String?
        
        public init(filterId: String) {
            self.filterId = filterId
        }
    }
    
    public struct ExceptionOptions: Sendable, Hashable, Codable {
        public var path: [ExceptionPathSegment]?
        public var breakMode: ExceptionBreakMode
        
        public init(breakMode: ExceptionBreakMode) {
            self.breakMode = breakMode
        }
    }
    
    public struct ExceptionPathSegment: Sendable, Hashable, Codable {
        public var negate: Bool?
        public var names: [String]
        
        public init(names: [String]) {
            self.names = names
        }
    }
    
    public struct FunctionBreakpoint: Sendable, Hashable, Codable {
        public var name: String
        public var condition: String?
        public var hitCondition: String?
        
        public init(name: String) {
            self.name = name
        }
    }
    
    public struct GotoTarget: Sendable, Hashable, Codable {
        public var id: Int
        public var label: String
        public var line: Int
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        public var instructionPointerReference: String?
        
        public init(id: Int, label: String, line: Int) {
            self.id = id
            self.label = label
            self.line = line
        }
    }
    
    public struct InstructionBreakpoint: Sendable, Hashable, Codable {
        public var instructionReference: String
        public var offset: Int?
        public var condition: String?
        public var hitCondition: String?
        public var mode: String?
        
        public init(instructionReference: String) {
            self.instructionReference = instructionReference
        }
    }
    
    public struct Module: Sendable, Hashable, Codable {
        // string or number
        public var id: JSONValue
        public var name: String
        public var path: String?
        public var isOptimized: Bool?
        public var isUserCode: Bool?
        public var version: String?
        public var symbolStatus: String?
        public var symbolFilePath: String?
        public var dateTimeStamp: String?
        public var addressRange: String?
        
        public init(id: JSONValue, name: String) {
            self.id = id
            self.name = name
        }
    }
    
    public struct Scope: Sendable, Hashable, Codable {
        public var name: String
        
        public struct PresentationHint: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let arguments: PresentationHint = "arguments"
            public static let locals: PresentationHint = "locals"
            public static let registers: PresentationHint = "registers"
            public static let returnValue: PresentationHint = "returnValue"
            public static let globals: PresentationHint = "globals"
            public static let upvalues: PresentationHint = "upvalues"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var presentationHint: PresentationHint?
        
        public var variablesReference: Int
        
        public var namedVariables: Int?
        public var indexedVariables: Int?
        public var expensive: Bool?
        
        public var source: Source?
        public var line: Int?
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        
        public init(name: String, variablesReference: Int) {
            self.name = name
            self.variablesReference = variablesReference
        }
    }
    
    public struct Source: Sendable, Hashable, Codable {
        public var name: String?
        public var path: String?
        public var sourceReference: Int?
        public var origin: String?
        public var sources: [Source]?
        public var adapterData: JSONValue?
        
        public var checksums: [Checksum]?
        
        public struct PresentationHint: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public static let normal: PresentationHint = "normal"
            public static let emphasize: PresentationHint = "emphasize"
            public static let deemphasize: PresentationHint = "deemphasize"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var presentationHint: PresentationHint?
        
        public init() {}
    }
    
    public struct SourceBreakpoint: Sendable, Hashable, Codable {
        public var line: Int
        public var column: Int?
        public var condition: String?
        public var hitCondition: String?
        public var logMessage: String?
        public var mode: String?
        
        public init(line: Int) {
            self.line = line
        }
    }
    
    public struct StackFrame: Sendable, Hashable, Codable {
        public var id: Int
        public var name: String?
        public var source: Source?
        public var line: Int
        public var column: Int
        public var endLine: Int?
        public var endColumn: Int?
        public var canRestart: Bool?
        public var instructionPointerReference: String?
        public var moduleId: JSONValue?
        
        public struct PresentationHint: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public static let normal: PresentationHint = "normal"
            public static let label: PresentationHint = "label"
            public static let subtle: PresentationHint = "subtle"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var presentationHint: PresentationHint?
        
        /// !!! Panic Extension
        public struct Attribute: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let async: Attribute = "async"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var attributes: [Attribute]?
        
        public init(id: Int, line: Int = 0, column: Int = 0) {
            self.id = id
            self.line = line
            self.column = column
        }
    }
    
    public struct StackFrameFormat: Sendable, Hashable, Codable {
        public var parameters: Bool?
        public var parameterTypes: Bool?
        public var parameterNames: Bool?
        public var parameterValues: Bool?
        public var line: Bool?
        public var module: Bool?
        public var includeAll: Bool?
        
        public init() {}
    }
    
    public enum SteppingGranularity: String, Sendable, Hashable, Codable {
        case statement
        case line
        case instruction
    }
    
    public struct StepInTarget: Sendable, Hashable, Codable {
        public var id: Int
        public var label: String
        
        public init(id: Int, label: String) {
            self.id = id
            self.label = label
        }
    }
    
    public struct Thread: Sendable, Hashable, Codable {
        public var id: Int
        public var name: String
        
        /// !!! Panic Extension
        public var description: String?
        
        public init(id: Int, name: String, description: String? = nil) {
            self.id = id
            self.name = name
            self.description = description
        }
    }
    
    public struct ValueFormat: Sendable, Hashable, Codable {
        var hex: Bool?
        
        public init() {}
    }
    
    public struct Variable: Sendable, Hashable, Codable {
        public var name: String
        public var value: String
        public var type: String?
        
        public struct PresentationHint: Sendable, Hashable, Codable {
            public struct Kind: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
                public typealias RawValue = String
                
                public static let property: Kind = "property"
                public static let method: Kind = "method"
                public static let `class`: Kind = "class"
                public static let data: Kind = "data"
                public static let event: Kind = "event"
                public static let baseClass: Kind = "baseClass"
                public static let innerClass: Kind = "innerClass"
                public static let interface: Kind = "interface"
                public static let mostDerivedClass: Kind = "mostDerivedClass"
                public static let virtual: Kind = "virtual"
                public static let dataBreakpoint: Kind = "dataBreakpoint"
                
                public let rawValue: String
                
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }
                
                public init(stringLiteral value: StringLiteralType) {
                    self.rawValue = value
                }
            }
            public var kind: Kind?
            
            public struct Attribute: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
                public typealias RawValue = String
                
                public static let `static`: Attribute = "static"
                public static let constant: Attribute = "constant"
                public static let readOnly: Attribute = "readOnly"
                public static let rawString: Attribute = "rawString"
                public static let hasObjectId: Attribute = "hasObjectId"
                public static let canHaveObjectId: Attribute = "canHaveObjectId"
                public static let hasSideEffects: Attribute = "hasSideEffects"
                public static let hasDataBreakpoint: Attribute = "hasDataBreakpoint"
                
                public let rawValue: String
                
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }
                
                public init(stringLiteral value: StringLiteralType) {
                    self.rawValue = value
                }
            }
            public var attributes: [Attribute]?
            
            public struct Visibility: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
                public typealias RawValue = String
                
                public static let `public`: Visibility = "public"
                public static let `private`: Visibility = "private"
                public static let protected: Visibility = "protected"
                public static let `internal`: Visibility = "internal"
                public static let `final`: Visibility = "final"
                
                public let rawValue: String
                
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }
                
                public init(stringLiteral value: StringLiteralType) {
                    self.rawValue = value
                }
            }
            public var visibility: Visibility?
            
            public var lazy: Bool?
            
            public init(kind: Kind?, attributes: [Attribute]?, visibility: Visibility?) {
                self.kind = kind
                self.attributes = attributes
                self.visibility = visibility
            }
        }
        public var presentationHint: PresentationHint?
        
        public var variablesReference: Int?
        public var evaluateName: String?
        
        public var namedVariables: Int?
        public var indexedVariables: Int?
        public var memoryReference: String?
        public var declarationLocationReference: Int?
        public var valueLocationReference: Int?
        
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
    
    
    public struct AttachRequest<Parameters>: DebugAdapterRequest where Parameters: Sendable & Codable {
        public static var command: String { "attach" }
        
        public var parameters: Parameters
        
        public typealias Result = Void
        
        public init(parameters: Parameters) {
            self.parameters = parameters
        }
        
        public init(from decoder: Decoder) throws {
            parameters = try Parameters(from: decoder)
        }
        
        public func encode(to encoder: Encoder) throws {
            try parameters.encode(to: encoder)
        }
    }
    
    public struct BreakpointLocationsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "breakpointLocations" }
        
        public var source: Source
        public var line: Int
        public var column: Int?
        public var endLine: Int?
        public var endColumn: Int?
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [BreakpointLocation]
        }
        
        public init(source: Source, line: Int) {
            self.source = source
            self.line = line
        }
    }
    
    public struct CompletionsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "completions" }
        
        public var frameId: Int?
        public var text: String
        public var column: Int
        public var line: Int?
        
        public struct Result: Sendable, Hashable, Codable {
            public var targets: [CompletionItem]
            
            public init(targets: [CompletionItem]) {
                self.targets = targets
            }
        }
        
        public init(frameId: Int? = nil, text: String, column: Int) {
            self.frameId = frameId
            self.text = text
            self.column = column
        }
    }
    
    public struct ConfigurationDoneRequest: DebugAdapterRequest {
        public static var command: String { "configurationDone" }
        
        public typealias Result = Void
        
        public init() {}
    }
    
    public struct ContinueRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "continue" }
        
        public var threadId: Int
        public var singleThread: Bool?
        
        public struct Result: Sendable, Hashable, Codable {
            public var allThreadsContinued: Bool?
            
            public init() {}
        }
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct DataBreakpointInfoRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "dataBreakpointInfo" }
        
        public var variablesReference: Int?
        public var name: String
        public var frameId: Int?
        public var bytes: Int?
        public var asAddress: Bool?
        public var mode: String?
        
        public struct Result: Sendable, Hashable, Codable {
            public var dataId: String?
            public var description: String
            public var accessTypes: [DataBreakpoint.AccessType]?
            public var canPersist: Bool?
        }
        
        public init(variablesReference: Int? = nil, name: String, frameId: Int? = nil) {
            self.variablesReference = variablesReference
            self.name = name
            self.frameId = frameId
        }
    }
    
    public struct DisassembleRequest: DebugAdapterRequestWithOptionalResult {
        public static var command: String { "disassemble" }
        
        public var memoryReference: String
        public var offset: Int?
        public var instructionOffset: Int?
        public var instructionCount: Int
        public var resolveSymbols: Bool?
        
        public struct Result: Sendable, Hashable, Codable {
            public var instructions: [DisassembledInstruction]
            
            public init(instructions: [DisassembledInstruction]) {
                self.instructions = instructions
            }
        }
        
        public init(memoryReference: String, instructionCount: Int) {
            self.memoryReference = memoryReference
            self.instructionCount = instructionCount
        }
    }
    
    public struct DisconnectRequest: DebugAdapterRequest {
        public static var command: String { "disconnect" }
        
        public var restart: Bool?
        public var terminateDebuggee: Bool?
        public var suspendDebuggee: Bool?
        
        public typealias Result = Void
        
        public init() {}
    }
    
    public struct EvaluateRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "evaluate" }
        
        public var expression: String
        public var frameId: Int?
        public var line: Int?
        public var column: Int?
        public var source: Source?
        
        public struct Context: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let variables: Context = "variables"
            public static let watch: Context = "watch"
            public static let repl: Context = "repl"
            public static let hover: Context = "hover"
            public static let clipboard: Context = "clipboard"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var context: Context?
        
        public var format: ValueFormat?
        
        public struct Result: Sendable, Hashable, Codable {
            public var result: String
            public var type: String?
            public var presentationHint: Variable.PresentationHint?
            public var variablesReference = 0
            public var namedVariables: Int?
            public var indexedVariables: Int?
            public var memoryReference: String?
            public var valueLocationReference: Int?
            
            public init(result: String) {
                self.result = result
            }
        }
        
        public init(expression: String) {
            self.expression = expression
        }
    }
    
    public struct ExceptionInfoRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "exceptionInfo" }
        
        public var threadId: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var exceptionId: String
            public var description: String?
            public var breakMode: ExceptionBreakMode
            public var details: ExceptionDetails?
            
            public init(exceptionId: String, breakMode: ExceptionBreakMode) {
                self.exceptionId = exceptionId
                self.breakMode = breakMode
            }
        }
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct GotoRequest: DebugAdapterRequest {
        public static var command: String { "goto" }
        
        public var threadId: Int
        public var targetId: Int
        
        public typealias Result = Void
        
        public init(threadId: Int, targetId: Int) {
            self.threadId = threadId
            self.targetId = targetId
        }
    }
    
    public struct GotoTargetsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "gotoTargets" }
        
        public var source: Source
        public var line: Int
        public var column: Int?
        
        public struct Result: Sendable, Hashable, Codable {
            public var targets: [GotoTarget]
            
            public init(targets: [GotoTarget]) {
                self.targets = targets
            }
        }
        
        public init(source: Source, line: Int) {
            self.source = source
            self.line = line
        }
    }
    
    public struct InitializeRequest: DebugAdapterRequestWithOptionalResult {
        public static var command: String { "initialize" }
        
        public var clientID: String?
        public var clientName: String?
        public var adapterID: String
        public var locale: String?
        public var linesStartAt1: Bool?
        public var columnsStartAt1: Bool?
        
        public struct PathFormat: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let path: PathFormat = "path"
            public static let uri: PathFormat = "uri"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var pathFormat: PathFormat?
        
        public var supportsVariableType: Bool?
        public var supportsVariablePaging: Bool?
        public var supportsRunInTerminalRequest: Bool?
        public var supportsMemoryReferences: Bool?
        public var supportsProgressReporting: Bool?
        public var supportsInvalidatedEvent: Bool?
        public var supportsMemoryEvent: Bool?
        public var supportsArgsCanBeInterpretedByShell: Bool?
        public var supportsStartDebuggingRequest: Bool?
        public var supportsANSIStyling: Bool?
        
        public typealias Result = Capabilities
        
        public init(adapterID: String) {
            self.adapterID = adapterID
        }
        
        public init<T>(adapterID: T) where T: RawRepresentable, T.RawValue == String {
            self.adapterID = adapterID.rawValue
        }
    }
    
    public struct LaunchRequest<Parameters>: DebugAdapterRequest where Parameters: Sendable & Codable {
        public static var command: String { "launch" }
        
        public var parameters: Parameters
        
        public typealias Result = Void
        
        public init(parameters: Parameters) {
            self.parameters = parameters
        }
        
        public init(from decoder: Decoder) throws {
            parameters = try Parameters(from: decoder)
        }
        
        public func encode(to encoder: Encoder) throws {
            try parameters.encode(to: encoder)
        }
    }
    
    public struct LoadedSourcesRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "loadedSources" }
        
        public struct Result: Sendable, Hashable, Codable {
            public var sources: [Source]
            
            public init(sources: [Source]) {
                self.sources = sources
            }
        }
        
        public init() {}
    }
    
    public struct LocationsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "locations" }
        
        public var locationReference: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var source: Source
            public var line: Int
            public var column: Int?
            public var endLine: Int?
            public var endColumn: Int?
            
            public init(source: Source, line: Int) {
                self.source = source
                self.line = line
            }
        }
        
        public init(locationReference: Int) {
            self.locationReference = locationReference
        }
    }
    
    public struct NextRequest: DebugAdapterRequest {
        public static var command: String { "next" }
        
        public var threadId: Int
        public var singleThread: Bool?
        public var granularity: SteppingGranularity?
        
        public typealias Result = Void
        
        public init(threadId: Int, granularity: SteppingGranularity? = nil) {
            self.threadId = threadId
            self.granularity = granularity
        }
    }
    
    public struct PauseRequest: DebugAdapterRequest {
        public static var command: String { "pause" }
        
        public var threadId: Int
        
        public typealias Result = Void
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct ReadMemoryRequest: DebugAdapterRequestWithOptionalResult {
        public static var command: String { "readMemory" }
        
        public var memoryReference: String
        public var offset: Int?
        public var count: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var address: String
            public var unreadableBytes: Int?
            public var data: String?
            
            public init(address: String) {
                self.address = address
            }
        }
        
        public init(memoryReference: String, count: Int) {
            self.memoryReference = memoryReference
            self.count = count
        }
    }
    
    public struct RestartRequest<Arguments>: DebugAdapterRequest where Arguments: Sendable & Codable {
        public static var command: String { "restart" }
        
        public var arguments: Arguments?
        
        public typealias Result = Void
        
        public init(arguments: Arguments? = nil) {
            self.arguments = arguments
        }
    }
    
    public struct RestartFrameRequest: DebugAdapterRequest {
        public static var command: String { "restartFrame" }
        
        public var frameId: Int
        
        public typealias Result = Void
        
        public init(frameId: Int) {
            self.frameId = frameId
        }
    }
    
    public struct ReverseContinueRequest: DebugAdapterRequest {
        public static var command: String { "reverseContinue" }
        
        public var threadId: Int
        public var singleThread: Bool?
        
        public typealias Result = Void
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct RunInTerminalRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "runInTerminal" }
        
        public var cmd: String
        public var args: [String]
        public var env: [String: JSONValue]?
        public var argsCanBeInterpretedByShell: Bool?
        
        public enum Kind: Sendable, Hashable, Codable {
            case integrated
            case external
        }
        public var kind: Kind?
        
        public var title: String?
        
        public struct Result: Sendable, Hashable, Codable {
            public var processId: Int?
            public var shellProcessId: Int?
            
            public init(processId: Int?, shellProcessId: Int?) {
                self.processId = processId
                self.shellProcessId = shellProcessId
            }
        }
        
        public init(cmd: String, args: [String]) {
            self.cmd = cmd
            self.args = args
        }
    }
    
    public struct ScopesRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "scopes" }
        
        public var frameId: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var scopes: [Scope]
            
            public init(scopes: [Scope]) {
                self.scopes = scopes
            }
        }
        
        public init(frameId: Int) {
            self.frameId = frameId
        }
    }
    
    public struct SetBreakpointsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setBreakpoints" }
        
        public var source: Source
        public var breakpoints: [SourceBreakpoint]?
        public var lines: [Int]?
        public var sourceModified: Bool?
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [Breakpoint]
            
            public init(breakpoints: [Breakpoint]) {
                self.breakpoints = breakpoints
            }
        }
        
        public init(source: Source) {
            self.source = source
        }
    }
    
    public struct SetDataBreakpointsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setDataBreakpoints" }
        
        public var breakpoints: [DataBreakpoint]
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [Breakpoint]
            
            public init(breakpoints: [Breakpoint]) {
                self.breakpoints = breakpoints
            }
        }
        
        public init(breakpoints: [DataBreakpoint]) {
            self.breakpoints = breakpoints
        }
    }
    
    public struct SetExceptionBreakpointsRequest: DebugAdapterRequestWithOptionalResult {
        public static var command: String { "setExceptionBreakpoints" }
        
        public var filters: [String]?
        public var filterOptions: [ExceptionFilterOptions]?
        public var exceptionOptions: [ExceptionOptions]?
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [Breakpoint]
            
            public init(breakpoints: [Breakpoint]) {
                self.breakpoints = breakpoints
            }
        }
        
        public init() {}
    }
    
    public struct SetExpressionRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setExpression" }
        
        public var expression: String
        public var value: String
        public var frameId: Int?
        public var format: ValueFormat?
        
        public struct Result: Sendable, Hashable, Codable {
            public var value: String
            public var type: String?
            public var presentationHint: Variable.PresentationHint?
            public var variablesReference: Int?
            public var namedVariables: Int?
            public var indexedVariables: Int?
            public var memoryReference: String?
            public var valueLocationReference: Int?
            
            public init(value: String) {
                self.value = value
            }
        }
        
        public init(expression: String, value: String) {
            self.expression = expression
            self.value = value
        }
    }
    
    public struct SetFunctionBreakpointsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setFunctionBreakpoints" }
        
        public var breakpoints: [FunctionBreakpoint]
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [Breakpoint]
            
            public init(breakpoints: [Breakpoint]) {
                self.breakpoints = breakpoints
            }
        }
        
        public init(breakpoints: [FunctionBreakpoint]) {
            self.breakpoints = breakpoints
        }
    }
    
    public struct SetInstructionBreakpointsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setInstructionBreakpoints" }
        
        public var breakpoints: [InstructionBreakpoint]
        
        public struct Result: Sendable, Hashable, Codable {
            public var breakpoints: [Breakpoint]
            
            public init(breakpoints: [Breakpoint]) {
                self.breakpoints = breakpoints
            }
        }
        
        public init(breakpoints: [InstructionBreakpoint]) {
            self.breakpoints = breakpoints
        }
    }
    
    public struct SetVariableRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "setVariable" }
        
        public var variablesReference: Int
        public var name: String
        public var value: String
        public var format: ValueFormat?
        
        public struct Result: Sendable, Hashable, Codable {
            public var value: String
            public var type: String?
            public var variablesReference: Int?
            public var namedVariables: Int?
            public var indexedVariables: Int?
            public var memoryReference: String?
            public var valueLocationReference: Int?
            
            public init(value: String) {
                self.value = value
            }
        }
        
        public init(variablesReference: Int, name: String, value: String) {
            self.variablesReference = variablesReference
            self.name = name
            self.value = value
        }
    }
    
    public struct SourceRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "source" }
        
        public var source: Source?
        public var sourceReference: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var content: String
            public var mimeType: String?
            
            public init(content: String, mimeType: String?) {
                self.content = content
                self.mimeType = mimeType
            }
        }
        
        public init(sourceReference: Int) {
            self.sourceReference = sourceReference
        }
    }
    
    public struct StackTraceRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "stackTrace" }
        
        public var threadId: Int
        public var startFrame: Int?
        public var levels: Int?
        public var format: StackFrameFormat?
        
        public struct Result: Sendable, Hashable, Codable {
            public var stackFrames: [StackFrame]
            public var totalFrames: Int {
                return stackFrames.count
            }
            
            public init(stackFrames: [StackFrame]) {
                self.stackFrames = stackFrames
            }
        }
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct StartDebuggingRequest: DebugAdapterRequest {
        public static var command: String { "startDebugging" }
        
        public var configuration: [String: JSONValue]
        
        public enum Request: String, Sendable, Hashable, Codable {
            case launch
            case attach
        }
        public var request: Request
        
        public typealias Result = Void
        
        public init(configuration: [String: JSONValue], request: Request) {
            self.configuration = configuration
            self.request = request
        }
    }
    
    public struct StepBackRequest: DebugAdapterRequest {
        public static var command: String { "stepBack" }
        
        public var threadId: Int
        public var singleThread: Bool?
        public var granularity: SteppingGranularity?
        
        public typealias Result = Void
        
        public init(threadId: Int, granularity: SteppingGranularity? = nil) {
            self.threadId = threadId
            self.granularity = granularity
        }
    }
    
    public struct StepInRequest: DebugAdapterRequest {
        public static var command: String { "stepIn" }
        
        public var threadId: Int
        public var singleThread: Bool?
        public var targetId: Int?
        public var granularity: SteppingGranularity?
        
        public typealias Result = Void
        
        public init(threadId: Int, targetId: Int? = nil, granularity: SteppingGranularity? = nil) {
            self.threadId = threadId
            self.targetId = targetId
            self.granularity = granularity
        }
    }
    
    public struct StepInTargetsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "stepInTargets" }
        
        public var frameId: Int
        
        public struct Result: Sendable, Hashable, Codable {
            public var targets: [StepInTarget]
            
            public init(targets: [StepInTarget]) {
                self.targets = targets
            }
        }
        
        public init(frameId: Int) {
            self.frameId = frameId
        }
    }
    
    public struct StepOutRequest: DebugAdapterRequest {
        public static var command: String { "stepOut" }
        
        public var threadId: Int
        public var singleThread: Bool?
        public var granularity: SteppingGranularity?
        
        public typealias Result = Void
        
        public init(threadId: Int, granularity: SteppingGranularity? = nil) {
            self.threadId = threadId
            self.granularity = granularity
        }
    }
    
    public struct ThreadsRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "threads" }
        
        public struct Result: Sendable, Hashable, Codable {
            public var threads: [Thread]
            
            public init(threads: [Thread]) {
                self.threads = threads
            }
        }
        
        public init() {}
    }
    
    public struct TerminateRequest: DebugAdapterRequest {
        public static var command: String { "terminate" }
        
        public var restart: Bool?
        
        public typealias Result = Void
        
        public init(restart: Bool) {
            self.restart = restart
        }
    }
    
    public struct TerminateThreadsRequest: DebugAdapterRequest {
        public static var command: String { "terminateThreads" }
        
        public var threadIds: [Int]?
        
        public typealias Result = Void
        
        public init(threadIds: [Int]?) {
            self.threadIds = threadIds
        }
    }
    
    public struct VariablesRequest: DebugAdapterRequestWithRequiredResult {
        public static var command: String { "variables" }
        
        public var variablesReference: Int
        
        public enum Filter: String, Sendable, Hashable, Codable {
            case indexed
            case named
        }
        public var filter: Filter?
        
        public var start: Int?
        public var count: Int?
        
        public var format: ValueFormat?
        
        public struct Result: Sendable, Hashable, Codable {
            public var variables: [Variable]
            
            public init(variables: [Variable]) {
                self.variables = variables
            }
        }
        
        public init(variablesReference: Int) {
            self.variablesReference = variablesReference
        }
    }
    
    public struct WriteMemoryRequest: DebugAdapterRequestWithOptionalResult {
        public static var command: String { "writeMemory" }
        
        public var memoryReference: String
        public var offset: Int?
        public var allowPartial: Bool?
        public var data: String
        
        public struct Result: Sendable, Hashable, Codable {
            public var offset: Int?
            public var bytesWritten: Int?
            
            public init() {}
        }
        
        public init(memoryReference: String, data: String) {
            self.memoryReference = memoryReference
            self.data = data
        }
    }
    
    
    public struct BreakpointEvent: DebugAdapterEvent {
        public static var event: String { "breakpoint" }
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let changed: Reason = "changed"
            public static let new: Reason = "new"
            public static let removed: Reason = "removed"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason
        
        public var breakpoint: Breakpoint
        
        public init(reason: Reason, breakpoint: Breakpoint) {
            self.reason = reason
            self.breakpoint = breakpoint
        }
    }
    
    public struct CapabilitiesEvent: DebugAdapterEvent {
        public static var event: String { "capabilities" }
        
        public var capabilities: Capabilities
        
        public init(capabilities: Capabilities) {
            self.capabilities = capabilities
        }
    }
    
    public struct ContinuedEvent: DebugAdapterEvent {
        public static var event: String { "continued" }
        
        public var threadId: Int
        public var allThreadsContinued: Bool?
        
        public init(threadId: Int) {
            self.threadId = threadId
        }
    }
    
    public struct ExitedEvent: DebugAdapterEvent {
        public static var event: String { "exited" }
        
        public var exitCode: Int
        
        public init(exitCode: Int) {
            self.exitCode = exitCode
        }
    }
    
    public struct InitializedEvent: DebugAdapterEvent {
        public static var event: String { "initialized" }
        
        public init() {}
    }
    
    public struct InvalidatedEvent: DebugAdapterEvent {
        public static var event: String { "invalidated" }
        
        public struct Area: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let all: Area = "all"
            public static let stacks: Area = "stacks"
            public static let threads: Area = "threads"
            public static let variables: Area = "variables"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var areas: [Area]?
        public var threadId: Int?
        public var stackFrameId: Int?
        
        public init() {}
    }
    
    public struct LoadedSourceEvent: DebugAdapterEvent {
        public static var event: String { "loadedSource" }
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let new: Reason = "new"
            public static let changed: Reason = "changed"
            public static let removed: Reason = "removed"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason
        
        public var source: Source
        
        public init(reason: Reason, source: Source) {
            self.reason = reason
            self.source = source
        }
    }
    
    public struct MemoryEvent: DebugAdapterEvent {
        public static var event: String { "memory" }
        
        public var memoryReference: String
        public var offset: Int
        public var count: Int
        
        public init(memoryReference: String, offset: Int, count: Int) {
            self.memoryReference = memoryReference
            self.offset = offset
            self.count = count
        }
    }
    
    public struct ModuleEvent: DebugAdapterEvent {
        public static var event: String { "module" }
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let new: Reason = "new"
            public static let changed: Reason = "changed"
            public static let removed: Reason = "removed"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason
        
        public var module: Module
        
        public init(reason: Reason, module: Module) {
            self.reason = reason
            self.module = module
        }
    }
    
    public struct OutputEvent: DebugAdapterEvent {
        public static var event: String { "output" }
        
        public struct Category: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let console: Category = "console"
            public static let important: Category = "important"
            public static let standardOutput: Category = "stdout"
            public static let standardError: Category = "stderr"
            public static let telemetry: Category = "telemetry"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var category: Category?
        
        public var output: String
        
        public enum Group: String, Sendable, Hashable, Codable {
            case start
            case startCollapsed
            case end
        }
        public var group: Group?
        
        public var variablesReference: Int32?
        public var source: Source?
        public var line: Int?
        public var column: Int?
        public var data: JSONValue?
        public var locationReference: Int?
        
        public init(output: String, category: Category? = nil) {
            self.output = output
            self.category = category
        }
    }
    
    public struct ProcessEvent: DebugAdapterEvent {
        public static var event: String { "process" }
        
        public var name: String
        public var systemProcessId: Int?
        public var isLocalProcess: Bool?
        
        public enum StartMethod: String, Sendable, Hashable, Codable {
            case launch
            case attach
            case attachForSuspendedLaunch
        }
        public var startMethod: StartMethod?
        
        public var pointerSize: Int?
        
        public init(name: String) {
            self.name = name
        }
    }
    
    public struct ProgressEndEvent: DebugAdapterEvent {
        public static var event: String { "progressEnd" }
        
        public var progressId: String
        public var message: String?
        
        public init(progressId: String) {
            self.progressId = progressId
        }
    }
    
    public struct ProgressStartEvent: DebugAdapterEvent {
        public static var event: String { "progressStart" }
        
        public var progressId: String
        public var title: String
        public var requestId: Int?
        public var cancellable: Bool?
        public var message: String?
        public var percentage: Int?
        
        public init(progressId: String, title: String) {
            self.progressId = progressId
            self.title = title
        }
    }
    
    public struct ProgressUpdateEvent: DebugAdapterEvent {
        public static var event: String { "progressUpdate" }
        
        public var progressId: String
        public var message: String?
        public var percentage: Int?
        
        public init(progressId: String) {
            self.progressId = progressId
        }
    }
    
    public struct StoppedEvent: DebugAdapterEvent {
        public static var event: String { "stopped" }
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let step: Reason = "step"
            public static let breakpoint: Reason = "breakpoint"
            public static let exception: Reason = "exception"
            public static let pause: Reason = "pause"
            public static let entry: Reason = "entry"
            public static let goto: Reason = "goto"
            public static let functionBreakpoint: Reason = "function breakpoint"
            public static let dataBreakpoint: Reason = "data breakpoint"
            public static let instructionBreakpoint: Reason = "instruction breakpoint"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason
        
        public var description: String?
        public var threadId: Int?
        public var preserveFocusHint: Bool?
        public var text: String?
        public var allThreadsStopped: Bool?
        public var hitBreakpointIds: [Int]?
        
        public init(reason: Reason) {
            self.reason = reason
        }
    }
    
    public struct TerminatedEvent: DebugAdapterEvent {
        public static var event: String { "terminated" }
        
        public var restart: JSONValue?
        
        public init() {}
    }
    
    public struct ThreadEvent: DebugAdapterEvent {
        public static var event: String { "thread" }
        
        public var threadId: Int
        
        public struct Reason: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            public typealias RawValue = String
            
            public static let started: Reason = "started"
            public static let exited: Reason = "exited"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var reason: Reason
        
        public init(threadId: Int, reason: Reason) {
            self.threadId = threadId
            self.reason = reason
        }
    }
}
