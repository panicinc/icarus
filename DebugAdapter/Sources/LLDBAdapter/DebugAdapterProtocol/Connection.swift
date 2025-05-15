import Foundation

/// A connection implementing the messaging layer of the Debug Adapter Protocol.
/// https://microsoft.github.io/debug-adapter-protocol/
public final class DebugAdapterConnection {
    /// The transport on which the connection will send and receive messages.
    public let transport: DebugAdapterTransport
    
    /// Options for customizing the behavior of a connection.
    public struct Configuration {
        /// The queue on which the configuration's block handlers will be invoked.
        /// If `nil` then the blocks will be invoked on an arbitrary queue.
        public var messageQueue: DispatchQueue?
        
        /// Invoked when the connection stops, after all pending messages have been dispatched.
        /// The optional error will be populated if the stop was caused by the underlying transport encountering an error.
        public var invalidationHandler: ((Error?) -> Void)?
        
        /// Invoked to log details about what messages are sent and received from the receiver, as well as errors that may occur.
        public var loggingHandler: ((@autoclosure @escaping () -> (String)) -> Void)?
        
        /// Invoked to handle requests.
        public var requestHandler: DebugAdapterRequestHandler?
        
        /// Invoked to handle events.
        public var eventHandler: DebugAdapterEventHandler?
        
        public init() {}
    }
    public private(set) var configuration = Configuration()
    
    private static let queueSpecific = DispatchSpecificKey<DebugAdapterConnection>()
    private let queue: DispatchQueue
    
    public init(transport: DebugAdapterTransport, configuration: Configuration? = nil) {
        self.transport = transport
        if let configuration {
            self.configuration = configuration
        }
        
        queue = DispatchQueue(label: "com.panic.debugadapter-connection")
        queue.setSpecific(key: Self.queueSpecific, value: self)
    }
    
    /// Enqueues a block on the receiver's internal serial dispatch queue.
    /// If the current queue is that serial queue the block will be executed immediately.
    public func perform(_ block: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: Self.queueSpecific) === self {
            block()
        }
        else {
            queue.async(execute: block)
        }
    }
    
    private func performOnMessageQueue(_ queue: DispatchQueue? = nil, _ block: @escaping () -> Void) {
        if let messageQueue = queue ?? configuration.messageQueue {
            messageQueue.async(execute: block)
        }
        else {
            block()
        }
    }
    
    /// Enqueues an update to the receiver's configuration.
    public func setConfiguration(_ configuration: Configuration) {
        perform { [weak self] in
            self?.configuration = configuration
        }
    }
    
    private var isRunning = false
    private var startReply: ((Error?) -> Void, DispatchQueue?)?
    private var transportHandler: TransportHandler?
    
    /// Starts the connection, which also sets up the transport.
    public func start(replyOn queue: DispatchQueue? = nil, reply: @escaping (Error?) -> Void) {
        perform { [weak self] in
            guard let self else { return }
            
            guard !self.isRunning else {
                preconditionFailure("Cannot restart a connection that has already been started.")
            }
            
            self.isRunning = true
            self.startReply = (reply, queue)
            
            let transportHandler = TransportHandler()
            transportHandler.connection = self
            self.transportHandler = transportHandler
            
            self.transport.setUp(handler: transportHandler)
        }
    }
    
    /// Starts the connection, which also sets up the transport.
    public func start() {
        start(replyOn: nil, reply: { _ in })
    }
    
    /// Stops the connection, which also stops the transport.
    /// If any requests are outstanding they are cancelled by throwing a cancellation error.
    /// If the connection is not running, this method does nothing.
    public func stop(error: Error? = nil) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            let configuration = self.configuration
            
            self.transport.tearDown()
            self.transportHandler = nil
            self.isRunning = false
            
            if let (reply, queue) = startReply {
                self.startReply = nil
                if let queue {
                    queue.async {
                        reply(error)
                    }
                }
                else {
                    reply(error)
                }
            }
            
            self.performOnMessageQueue {
                configuration.invalidationHandler?(error)
            }
            
            // Answer any unreplied requests
            let pendingRequests = self.pendingRequests
            if pendingRequests.count > 0 {
                self.pendingRequests = [:]
                
                let requestError = error ?? ResponseError(message: .cancelled)
                for (_, (_, queue, handler)) in pendingRequests {
                    self.performOnMessageQueue(queue) {
                        handler(.failure(requestError))
                    }
                }
            }
        }
    }
    
    private class TransportHandler: DebugAdapterTransportHandler {
        weak var connection: DebugAdapterConnection?
        
        func didConnect() {
            connection?.transportDidConnect()
        }
        
        func didTerminate(withError error: Error?) {
            connection?.stop(error: error)
        }
        
        func didRead(data: Data) {
            connection?.transportDidRead(data: data)
        }
    }
    
    private func transportDidConnect() {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if let (reply, queue) = startReply {
                self.startReply = nil
                if let queue {
                    queue.async {
                        reply(nil)
                    }
                }
                else {
                    reply(nil)
                }
            }
            
            self.readNextMessage()
        }
    }
    
    private func transportDidRead(data: Data) {
        perform { [weak self] in
            guard let self else {
                return
            }
            self.inputDataBuffer.append(data)
            self.readMessage()
        }
    }
    
    private enum Message: Codable {
        case request(Int, String)
        case response(Int, Int, String, Bool, String?)
        case event(Int, String)
        
        enum CodingKeys: String, CodingKey {
            case seq
            case type
            case command
            case event
            case requestSeq = "request_seq"
            case success
            case message
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "request":
                let seq = try container.decode(Int.self, forKey: .seq)
                let command = try container.decode(String.self, forKey: .command)
                self = .request(seq, command)
                
            case "response":
                let seq = try container.decode(Int.self, forKey: .seq)
                let requestSeq = try container.decode(Int.self, forKey: .requestSeq)
                let command = try container.decode(String.self, forKey: .command)
                let success = try container.decode(Bool.self, forKey: .success)
                let message = try container.decodeIfPresent(String.self, forKey: .message)
                self = .response(seq, requestSeq, command, success, message)
                
            case "event":
                let seq = try container.decode(Int.self, forKey: .seq)
                let event = try container.decode(String.self, forKey: .event)
                self = .event(seq, event)
                
            default:
                throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: "Unsupported message type \(type)")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case let .request(seq, command):
                try container.encode(seq, forKey: .seq)
                try container.encode("request", forKey: .type)
                try container.encode(command, forKey: .command)
                
            case let .response(seq, requestSeq, command, success, message):
                try container.encode(seq, forKey: .seq)
                try container.encode("response", forKey: .type)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(success, forKey: .success)
                try container.encode(message, forKey: .message)
                
            case let .event(seq, event):
                try container.encode(seq, forKey: .seq)
                try container.encode("event", forKey: .type)
                try container.encode(event, forKey: .event)
            }
        }
    }
    
    private static let CRLF = Data(bytes: [0x0D, 0x0A] as [UInt8], count: 2)
    
    private static func data<Message>(forMessage message: Message) throws -> Data where Message: Encodable {
        var data = Data()
        
        let CRLF = CRLF
        
        let content = try JSONEncoder().encode(message)
        
        let headers: [String: String] = [
            "Content-Length": "\(content.count)"
        ]
        
        // Headers
        headers.forEach { key, value in
            let string = "\(key): \(value)"
            if let val = string.data(using: .utf8) {
                data.append(val)
                data.append(CRLF)
            }
        }
        
        data.append(CRLF)
        data.append(content)
        
        return data
    }
    
    private static func prettyPrintedString<T: Codable>(for object: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(object) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private static func prettyPrintedString(forJSONData data: Data) -> String? {
        guard let object = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return nil
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(object) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private struct RequestMessage<Request: DebugAdapterRequest>: Codable {
        let seq: Int
        let arguments: Request?
        
        init(seq: Int, request: Request) {
            self.seq = seq
            self.arguments = request
        }
        
        enum CodingKeys: CodingKey {
            case seq
            case type
            case command
            case arguments
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seq = try container.decode(Int.self, forKey: .seq)
            arguments = try container.decodeIfPresent(Request.self, forKey: .arguments)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("request", forKey: .type)
            try container.encode(Request.command, forKey: .command)
            try container.encode(arguments, forKey: .arguments)
        }
    }
    
    public struct ResponseError: Error, Sendable {
        public struct Message: RawRepresentable, Sendable, ExpressibleByStringLiteral, Hashable, Codable {
            /// The request was cancelled.
            public static let cancelled: Message = "cancelled"
            
            /// The request may be retried once the adapter is in a 'stopped'
            /// state.
            public static let notStopped: Message = "notStopped"
            
            public let rawValue: String
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.rawValue = value
            }
        }
        public var message: Message?
        
        public struct Details: Sendable, Codable {
            public var id: Int
            public var format: String
            public var variables: [String: String]?
            public var sendTelemetry: Bool?
            public var showUser: Bool?
            public var url: String?
            public var urlLabel: String?
            
            public init(id: Int, format: String) {
                self.id = id
                self.format = format
            }
        }
        public var details: Details?
        
        /// If the error does not follow the DAP spec, the `body` can be stored
        /// as a raw JSON value.
        public var body: JSONValue?
        
        public init(message: Message? = nil, details: Details? = nil, body: JSONValue? = nil) {
            self.message = message
            self.details = details
            self.body = body
        }
        
        public init(message: String) {
            self.message = Message(rawValue: message)
        }
        
        public static var cancelled: ResponseError { .init(message: .cancelled) }
        
        public static func unsupportedRequest<Request>(_ request: Request) -> ResponseError where Request: DebugAdapterRequest {
            return .init(message: "unsupportedRequest<\(Request.command)>")
        }
        
        public static func unsupportedRequest(_ request: String) -> ResponseError {
            return .init(message: "unsupportedRequest<\(request)>")
        }
        
        public var errorDescription: String? {
            switch message {
            case .cancelled:
                return "The request was cancelled."
            case .notStopped:
                return "The request cannot be performed until execution is stopped."
            default:
                return message?.rawValue ?? "The request failed."
            }
        }
    }
    
    private struct ResponseErrorBody: Codable {
        var error: ResponseError.Details
        
        private enum CodingKeys: CodingKey {
            case error
        }
        
        init(error: ResponseError.Details) {
            self.error = error
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            error = try container.decode(ResponseError.Details.self, forKey: .error)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(error, forKey: .error)
        }
    }
    
    private enum ResponseRequiredResultMessage<Result: Codable>: Codable {
        case success(seq: Int, requestSeq: Int, command: String, result: Result)
        case failure(seq: Int, requestSeq: Int, command: String, error: ResponseError)
        
        enum CodingKeys: String, CodingKey {
            case seq
            case type
            case requestSeq = "request_seq"
            case command
            case success
            case message
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let seq = try container.decode(Int.self, forKey: .seq)
            let requestSeq = try container.decode(Int.self, forKey: .requestSeq)
            let command = try container.decode(String.self, forKey: .command)
            
            let success = try container.decode(Bool.self, forKey: .success)
            if success {
                let result = try container.decode(Result.self, forKey: .body)
                self = .success(seq: seq, requestSeq: requestSeq, command: command, result: result)
            }
            else {
                // While the Debug Adapter Protocol defines recommendations for
                // returning error details, they are not strictly followed.
                let message = try container.decodeIfPresent(ResponseError.Message.self, forKey: .message)
                
                var error = ResponseError(message: message)
                
                if let body = try? container.decodeIfPresent(ResponseErrorBody.self, forKey: .body) {
                    error.details = body.error
                }
                else if let body = try container.decodeIfPresent(JSONValue.self, forKey: .body) {
                    error.body = body
                }
                
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, error: error)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("response", forKey: .type)
            
            switch self {
            case .success(seq: let seq, requestSeq: let requestSeq, command: let command, result: let result):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(true, forKey: .success)
                try container.encode(result, forKey: .body)
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, error: let error):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encodeIfPresent(error.message, forKey: .message)
                if let details = error.details {
                    try container.encode(ResponseErrorBody(error: details), forKey: .body)
                }
                else {
                    try container.encodeIfPresent(error.body, forKey: .body)
                }
            }
        }
    }
    
    private enum ResponseOptionalResultMessage<Result: Codable>: Codable {
        case success(seq: Int, requestSeq: Int, command: String, result: Result?)
        case failure(seq: Int, requestSeq: Int, command: String, error: ResponseError)
        
        enum CodingKeys: String, CodingKey {
            case seq
            case type
            case requestSeq = "request_seq"
            case command
            case success
            case message
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let seq = try container.decode(Int.self, forKey: .seq)
            let requestSeq = try container.decode(Int.self, forKey: .requestSeq)
            let command = try container.decode(String.self, forKey: .command)
            
            let success = try container.decode(Bool.self, forKey: .success)
            if success {
                let result = try container.decodeIfPresent(Result.self, forKey: .body)
                self = .success(seq: seq, requestSeq: requestSeq, command: command, result: result)
            }
            else {
                // While the Debug Adapter Protocol defines recommendations for
                // returning error details, they are not strictly followed.
                let message = try container.decodeIfPresent(ResponseError.Message.self, forKey: .message)
                
                var error = ResponseError(message: message)
                
                if let body = try? container.decodeIfPresent(ResponseErrorBody.self, forKey: .body) {
                    error.details = body.error
                }
                else if let body = try container.decodeIfPresent(JSONValue.self, forKey: .body) {
                    error.body = body
                }
                
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, error: error)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("response", forKey: .type)
            
            switch self {
            case .success(seq: let seq, requestSeq: let requestSeq, command: let command, result: let result):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(true, forKey: .success)
                try container.encode(result, forKey: .body)
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, error: let error):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encodeIfPresent(error.message, forKey: .message)
                if let details = error.details {
                    try container.encode(ResponseErrorBody(error: details), forKey: .body)
                }
                else {
                    try container.encodeIfPresent(error.body, forKey: .body)
                }
            }
        }
    }
    
    private enum ResponseVoidMessage: Codable {
        case success(seq: Int, requestSeq: Int, command: String)
        case failure(seq: Int, requestSeq: Int, command: String, error: ResponseError)
        
        enum CodingKeys: String, CodingKey {
            case seq
            case type
            case requestSeq = "request_seq"
            case command
            case success
            case message
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let seq = try container.decode(Int.self, forKey: .seq)
            let requestSeq = try container.decode(Int.self, forKey: .requestSeq)
            let command = try container.decode(String.self, forKey: .command)
            
            let success = try container.decode(Bool.self, forKey: .success)
            if success {
                self = .success(seq: seq, requestSeq: requestSeq, command: command)
            }
            else {
                // While the Debug Adapter Protocol defines recommendations for
                // returning error details, they are not strictly followed.
                let message = try container.decodeIfPresent(ResponseError.Message.self, forKey: .message)
                
                var error = ResponseError(message: message)
                
                if let body = try? container.decodeIfPresent(ResponseErrorBody.self, forKey: .body) {
                    error.details = body.error
                }
                else if let body = try container.decodeIfPresent(JSONValue.self, forKey: .body) {
                    error.body = body
                }
                
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, error: error)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("response", forKey: .type)
            
            switch self {
            case .success(seq: let seq, requestSeq: let requestSeq, command: let command):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(true, forKey: .success)
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, error: let error):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encodeIfPresent(error.message, forKey: .message)
                if let details = error.details {
                    try container.encode(ResponseErrorBody(error: details), forKey: .body)
                }
                else {
                    try container.encodeIfPresent(error.body, forKey: .body)
                }
            }
        }
    }
    
    private struct EventMessage<Event: DebugAdapterEvent>: Codable {
        let seq: Int
        let event: String
        let body: Event?
        
        init(seq: Int, event: Event) {
            self.seq = seq
            self.event = Event.event
            self.body = event
        }
        
        enum CodingKeys: CodingKey {
            case seq
            case type
            case event
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seq = try container.decode(Int.self, forKey: .seq)
            event = try container.decode(String.self, forKey: .event)
            body = try container.decodeIfPresent(Event.self, forKey: .body)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("event", forKey: .type)
            try container.encode(event, forKey: .event)
            try container.encode(body, forKey: .body)
        }
    }
    
    private struct RawRequestMessage<Arguments>: Codable, Sendable where Arguments: Codable & Sendable {
        let seq: Int
        let command: String
        let arguments: Arguments?
        
        init(seq: Int, command: String, arguments: Arguments?) {
            self.seq = seq
            self.command = command
            self.arguments = arguments
        }
        
        enum CodingKeys: CodingKey {
            case seq
            case type
            case command
            case arguments
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seq = try container.decode(Int.self, forKey: .seq)
            command = try container.decode(String.self, forKey: .command)
            arguments = try container.decodeIfPresent(Arguments.self, forKey: .arguments)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("request", forKey: .type)
            try container.encode(command, forKey: .command)
            try container.encodeIfPresent(arguments, forKey: .arguments)
        }
    }
    
    private enum RawResponseMessage<Result>: Codable, Sendable where Result: Codable & Sendable {
        case success(seq: Int, requestSeq: Int, command: String, result: Result?)
        case failure(seq: Int, requestSeq: Int, command: String, error: ResponseError)
        
        enum CodingKeys: String, CodingKey {
            case seq
            case type
            case requestSeq = "request_seq"
            case command
            case success
            case message
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let seq = try container.decode(Int.self, forKey: .seq)
            let requestSeq = try container.decode(Int.self, forKey: .requestSeq)
            let command = try container.decode(String.self, forKey: .command)
            
            let success = try container.decode(Bool.self, forKey: .success)
            if success {
                let result = try container.decodeIfPresent(Result.self, forKey: .body)
                self = .success(seq: seq, requestSeq: requestSeq, command: command, result: result)
            }
            else {
                // While the Debug Adapter Protocol defines recommendations for
                // returning error details, they are not strictly followed.
                let message = try container.decodeIfPresent(ResponseError.Message.self, forKey: .message)
                
                var error = ResponseError(message: message)
                
                if let body = try? container.decodeIfPresent(ResponseErrorBody.self, forKey: .body) {
                    error.details = body.error
                }
                else if let body = try container.decodeIfPresent(JSONValue.self, forKey: .body) {
                    error.body = body
                }
                
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, error: error)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("response", forKey: .type)
            
            switch self {
            case .success(seq: let seq, requestSeq: let requestSeq, command: let command, result: let result):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(true, forKey: .success)
                try container.encode(result, forKey: .body)
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, error: let error):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encodeIfPresent(error.message, forKey: .message)
                if let details = error.details {
                    try container.encode(ResponseErrorBody(error: details), forKey: .body)
                }
                else {
                    try container.encodeIfPresent(error.body, forKey: .body)
                }
            }
        }
    }
    
    private struct RawEventMessage<Body>: Codable, Sendable where Body: Codable & Sendable {
        let seq: Int
        let event: String
        let body: Body?
        
        init(seq: Int, event: String, body: Body?) {
            self.seq = seq
            self.event = event
            self.body = body
        }
        
        enum CodingKeys: CodingKey {
            case seq
            case type
            case event
            case body
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seq = try container.decode(Int.self, forKey: .seq)
            event = try container.decode(String.self, forKey: .event)
            body = try container.decodeIfPresent(Body.self, forKey: .body)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("event", forKey: .type)
            try container.encode(event, forKey: .event)
            try container.encode(body, forKey: .body)
        }
    }
    
    /// This struct exists purely for type inference of methods that encode errors.
    private struct EmptyCodable: Codable {}
    
    private func readNextMessage() {
        transport.readData(minimumIncompleteLength: 0)
    }
    
    private var inputDataBuffer = Data()
    private var inputDataOffset = 0
    private static let inputDataMaxOffset = 102400 // 100 KB
    
    private func readMessage() {
        let data = inputDataBuffer.subdata(in: inputDataOffset ..< inputDataBuffer.count)
        var consumedLength = 0
        var additionalRequiredLength = 0
        if readMessage(withData: data, consumedLength: &consumedLength, additionalRequiredLength: &additionalRequiredLength) {
            inputDataOffset += consumedLength
            
            if (inputDataOffset >= Self.inputDataMaxOffset) {
                // Reset the data buffer
                inputDataBuffer.removeSubrange(0 ..< inputDataOffset)
                inputDataOffset = 0
            }
            
            // Attempt to read the next message (if any)
            readMessage()
        }
        else if additionalRequiredLength > 0 {
            transport.readData(minimumIncompleteLength: additionalRequiredLength)
        }
        else {
            readNextMessage()
        }
    }
    
    private func readMessage(withData data: Data, consumedLength: inout Int, additionalRequiredLength: inout Int) -> Bool {
        // Parse Headers
        var headers: [String:String] = [:]
        var contentStartIdx = 0
        
        let CRLF = Self.CRLF
        
        var CRLFRange: Range<Int>?
        var searchRange = contentStartIdx ..< data.count
        repeat {
            CRLFRange = data.range(of: CRLF, options: [], in: searchRange)
            if let CRLFRange {
                let headerDataRange = searchRange.lowerBound ..< CRLFRange.lowerBound
                if headerDataRange.count == 0 {
                    // End of headers
                    contentStartIdx = CRLFRange.upperBound
                    break
                }
                else {
                    // Header
                    let headerData = data[headerDataRange]
                    if let headerString = String(data: headerData, encoding: .utf8),
                       let separatorRange = headerString.range(of: ": ") {
                        let headerName = headerString[headerString.startIndex ..< separatorRange.lowerBound]
                        let headerValue = headerString[separatorRange.upperBound ..< headerString.endIndex]
                        headers[String(headerName)] = String(headerValue)
                    }
                }
                
                searchRange = CRLFRange.upperBound ..< data.count
            }
            else {
                // Reached end of buffer before headers ended; Not enough data received
                consumedLength = 0
                additionalRequiredLength = 0
                return false
            }
        } while CRLFRange != nil
        
        // Content Length
        let contentLengthHeader = headers["Content-Length"]
        let contentLength = contentLengthHeader != nil ? Int(contentLengthHeader!) ?? 0 : 0
        
        if contentStartIdx + contentLength > data.count {
            // Not enough data received yet
            consumedLength = 0
            additionalRequiredLength = (contentStartIdx + contentLength) - data.count
            return false
        }
        
        additionalRequiredLength = 0
        consumedLength = contentStartIdx + contentLength
        
        // Content
        let contentData = data[contentStartIdx ..< contentStartIdx + contentLength]
        
        do {
            let decoder = JSONDecoder()
            let msg = try decoder.decode(Message.self, from: contentData)
            
            let configuration = configuration
            
            switch msg {
            case let .request(seq, command):
                if let handler = configuration.requestHandler {
                    self.performOnMessageQueue { [weak self] in
                        guard let self, self.isRunning else {
                            return
                        }
                        
                        configuration.loggingHandler?({
                            if let prettyString = Self.prettyPrintedString(forJSONData: contentData) {
                                return "Received DebugAdapter request: \(seq) \(command)\n\(prettyString)"
                            }
                            else {
                                return "Received DebugAdapter request: \(seq) \(command)"
                            }
                        }())
                        
                        let request = IncomingRequest(connection: self, command: command, seq: seq, data: contentData)
                        handler.handleRequest(request)
                    }
                }
                else {
                    // No handler set; Send method not supported.
                    self.send(responseToRequestID: seq, command: command, error: ResponseError(message: "unsupportedRequest"))
                }
                
            case let .response(_, requestSeq, command, _, _):
                if let (_, queue, handler) = pendingRequests[requestSeq] {
                    pendingRequests[requestSeq] = nil
                    
                    self.performOnMessageQueue(queue) {
                        configuration.loggingHandler?({
                            if let prettyString = Self.prettyPrintedString(forJSONData: contentData) {
                                return "Received DebugAdapter response: \(requestSeq) \(command)\n\(prettyString)"
                            }
                            else {
                                return "Received DebugAdapter response: \(requestSeq) \(command)"
                            }
                        }())
                        
                        handler(.success(contentData))
                    }
                }
                else {
                    if let loggingHandler = configuration.loggingHandler {
                        self.performOnMessageQueue {
                            loggingHandler({
                                if let prettyString = Self.prettyPrintedString(forJSONData: contentData) {
                                    return "Received DebugAdapter response to an unknown request: \(requestSeq)\n\(prettyString)"
                                }
                                else {
                                    return "Received DebugAdapter response to an unknown request: \(requestSeq)"
                                }
                            }())
                        }
                    }
                }
                
            case let .event(_, eventName):
                if let handler = configuration.eventHandler {
                    self.performOnMessageQueue {
                        configuration.loggingHandler?({
                            if let prettyString = Self.prettyPrintedString(forJSONData: contentData) {
                                return "Received DebugAdapter event: \(eventName)\n\(prettyString)"
                            }
                            else {
                                return "Received DebugAdapter event: \(eventName)"
                            }
                        }())
                        
                        let event = IncomingEvent(connection: self, event: eventName, data: contentData)
                        handler.handleEvent(event)
                    }
                }
                else {
                    if let loggingHandler = configuration.loggingHandler {
                        self.performOnMessageQueue {
                            loggingHandler({
                                if let prettyString = Self.prettyPrintedString(forJSONData: contentData) {
                                    return "Received ignored DebugAdapter event: \(eventName)\n\(prettyString)"
                                }
                                else {
                                    return "Received ignored DebugAdapter event: \(eventName)"
                                }
                            }())
                        }
                    }
                }
            }
        }
        catch {
            configuration.loggingHandler?("DebugAdapter could not decode message: \(error), \(String(data: data, encoding: .utf8) ?? "(nil)")")
        }
        
        return true
    }
    
    public struct IncomingRequest {
        public let connection: DebugAdapterConnection
        public let command: String
        private let seq: Int
        private let data: Data
        
        fileprivate init(connection: DebugAdapterConnection, command: String, seq: Int, data: Data) {
            self.connection = connection
            self.command = command
            self.seq = seq
            self.data = data
        }
    }
    
    public struct IncomingEvent {
        public let connection: DebugAdapterConnection
        public let event: String
        private let data: Data
        
        fileprivate init(connection: DebugAdapterConnection, event: String, data: Data) {
            self.connection = connection
            self.event = event
            self.data = data
        }
    }
    
    private func send<Request: DebugAdapterRequestWithRequiredResult>(responseTo request: Request, requestID: Int, result: Request.Result) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            do {
                let responseID = self.nextMessageID()
                let response = ResponseRequiredResultMessage<Request.Result>.success(seq: responseID, requestSeq: requestID, command: Request.command, result: result)
                
                let data = try Self.data(forMessage: response)
                try self.transport.write(data: data)
            }
            catch {
                self.send(responseToRequestID: requestID, command: Request.command, error: error)
            }
        }
    }
    
    private func send<Request: DebugAdapterRequestWithOptionalResult>(responseTo request: Request, requestID: Int, result: Request.Result?) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            do {
                let responseID = self.nextMessageID()
                let response = ResponseOptionalResultMessage<Request.Result>.success(seq: responseID, requestSeq: requestID, command: Request.command, result: result)
                
                let data = try Self.data(forMessage: response)
                try self.transport.write(data: data)
            }
            catch {
                self.send(responseToRequestID: requestID, command: Request.command, error: error)
            }
        }
    }
    
    private func send<Request: DebugAdapterRequest>(responseTo request: Request, requestID: Int) where Request.Result == Void {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            do {
                let responseID = self.nextMessageID()
                let response = ResponseVoidMessage.success(seq: responseID, requestSeq: requestID, command: Request.command)
                
                let data = try Self.data(forMessage: response)
                try self.transport.write(data: data)
            }
            catch {
                self.send(responseToRequestID: requestID, command: Request.command, error: error)
            }
        }
    }
    
    private func send<ResultType>(responseToRequestID requestID: Int, command: String, result: ResultType?) where ResultType: Codable & Sendable {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            do {
                let responseID = self.nextMessageID()
                let response = RawResponseMessage.success(seq: responseID, requestSeq: requestID, command: command, result: result)
                
                let data = try Self.data(forMessage: response)
                try self.transport.write(data: data)
            }
            catch {
                self.send(responseToRequestID: requestID, command: command, error: error)
            }
        }
    }
    
    private func send(responseToRequestID requestID: Int, command: String, error: Error) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            let message: String
            if let error = error as? LocalizedError {
                message = error.errorDescription ?? String(describing: error)
            }
            else {
                message = String(describing: error)
            }
            
            let responseID = self.nextMessageID()
            let responseError = ResponseError(message: message)
            let response = RawResponseMessage<EmptyCodable>.failure(seq: responseID, requestSeq: requestID, command: command, error: responseError)
            
            do {
                let data = try Self.data(forMessage: response)
                try self.transport.write(data: data)
            }
            catch {
                if let loggingHandler = self.configuration.loggingHandler {
                    self.performOnMessageQueue {
                        loggingHandler("DebugAdapter could not encode error response for request \"\(requestID)\": \(error)")
                    }
                }
            }
        }
    }
    
    private var messageID = 0
    
    private func nextMessageID() -> Int {
        let nextID = messageID
        if (nextID == .max) {
            messageID = 0
        }
        else {
            messageID += 1
        }
        return nextID
    }
    
    // MARK: - Sending Messages
    
    /// If `true`, then for any requests whose progress objects are cancelled
    /// the connection will automatically send a corresponding cancel request.
    public private(set) var supportsCancelRequest = false
    
    public func setSupportsCancelRequest(_ flag: Bool) {
        supportsCancelRequest = flag
    }
    
    public final class CancellationToken {
        fileprivate private(set) var isCancelled = false
        private weak var connection: DebugAdapterConnection?
        private var cancelHandlers: [() -> Void] = []
        
        fileprivate init(connection: DebugAdapterConnection) {
            self.connection = connection
        }
        
        fileprivate func onCancel(_ block: @escaping () -> Void) {
            connection?.perform { [weak self] in
                self?.cancelHandlers.append(block)
            }
        }
        
        public func cancel() {
            connection?.perform { [weak self] in
                guard let self, !self.isCancelled else {
                    return
                }
                
                self.isCancelled = true
                
                let handlers = self.cancelHandlers
                self.cancelHandlers = []
                for handler in handlers {
                    handler()
                }
            }
        }
    }
    
    private struct CancelRequest: DebugAdapterRequest {
        static let command: String = "cancel"
        
        typealias Result = Void
        
        var requestId: Int?
        var progressId: Int?
    }
    
    private func cancel(requestID: Int) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if let (method, queue, handler) = self.pendingRequests[requestID] {
                self.pendingRequests[requestID] = nil
                
                self.performOnMessageQueue(queue) {
                    if let loggingHandler = self.configuration.loggingHandler {
                        loggingHandler("Cancelling DebugAdapter request: \(requestID) \(method)")
                    }
                    
                    handler(.failure(ResponseError(message: .cancelled)))
                }
                
                self.send(CancelRequest(requestId: requestID)) { _ in }
            }
        }
    }
    
    private var pendingRequests: [Int: (String, DispatchQueue?, (Result<Data, Error>) -> Void)] = [:]
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequestWithRequiredResult>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<Request.Result, Error>) -> Void) -> CancellationToken {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> Void = { result in
                switch result {
                case let .success(data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseRequiredResultMessage<Request.Result>.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result))
                        case .failure(_, _, _, error: let error):
                            replyHandler(.failure(error))
                        }
                    }
                    catch {
                        replyHandler(.failure(error))
                    }
                    
                case .failure(error: let error):
                    replyHandler(.failure(error))
                }
            }
            self.pendingRequests[messageID] = (Request.command, queue, dataHandler)
            
            let message = RequestMessage(seq: messageID, request: request)
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.pendingRequests[messageID] = nil
                dataHandler(.failure(error))
            }
        }
        
        return token
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    public func send<Request: DebugAdapterRequestWithRequiredResult>(_ request: Request) async throws -> Request.Result {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequestWithOptionalResult>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<Request.Result?, Error>) -> Void) -> CancellationToken {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> Void = { result in
                switch result {
                case let .success(data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseOptionalResultMessage<Request.Result>.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result))
                        case .failure(_, _, _, let error):
                            replyHandler(.failure(error))
                        }
                    }
                    catch {
                        replyHandler(.failure(error))
                    }
                    
                case .failure(error: let error):
                    replyHandler(.failure(error))
                }
            }
            self.pendingRequests[messageID] = (Request.command, queue, dataHandler)
            
            let message = RequestMessage(seq: messageID, request: request)
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.pendingRequests[messageID] = nil
                dataHandler(.failure(error))
            }
        }
        
        return token
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    public func send<Request: DebugAdapterRequestWithOptionalResult>(_ request: Request) async throws -> Request.Result? {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequest>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<(), Error>) -> Void) -> CancellationToken where Request.Result == Void {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> Void = { result in
                switch result {
                case let .success(data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseVoidMessage.self, from: data)
                        
                        switch response {
                        case .success(_, _, _):
                            replyHandler(.success(()))
                        case .failure(_, _, _, error: let error):
                            replyHandler(.failure(error))
                        }
                    }
                    catch {
                        replyHandler(.failure(error))
                    }
                    
                case .failure(error: let error):
                    replyHandler(.failure(error))
                }
            }
            self.pendingRequests[messageID] = (Request.command, queue, dataHandler)
            
            let message = RequestMessage(seq: messageID, request: request)
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter request: \(messageID) \(Request.command)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.pendingRequests[messageID] = nil
                dataHandler(.failure(error))
            }
        }
        
        return token
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    public func send<Request: DebugAdapterRequest>(_ request: Request) async throws where Request.Result == Void {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a raw request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Arguments, ResultType>(command: String, arguments: Arguments?, resultType: ResultType.Type, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<ResultType?, Error>) -> Void) -> CancellationToken where Arguments: Codable & Sendable, ResultType: Codable & Sendable {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> Void = { result in
                switch result {
                case let .success(data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(RawResponseMessage<ResultType>.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result))
                        case .failure(_, _, _, error: let error):
                            replyHandler(.failure(error))
                        }
                    }
                    catch {
                        replyHandler(.failure(error))
                    }
                    
                case .failure(error: let error):
                    replyHandler(.failure(error))
                }
            }
            self.pendingRequests[messageID] = (command, queue, dataHandler)
            
            let message = RawRequestMessage(seq: messageID, command: command, arguments: arguments)
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter request: \(messageID) \(command)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter request: \(messageID) \(command)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.pendingRequests[messageID] = nil
                dataHandler(.failure(error))
            }
        }
        
        return token
    }
    
    /// Sends a raw request and returns when either a response is returned or the request is cancelled.
    /// This method will throw an error if the provided arguments are not JSON-serializable.
    public func send<Arguments, ResultType>(request command: String, arguments: Arguments?, resultType: ResultType.Type) async throws -> ResultType? where Arguments: Codable & Sendable, ResultType: Codable & Sendable {
        return try await withUnsafeThrowingContinuation { continuation in
            send(command: command, arguments: arguments, resultType: resultType) { result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends an event and continues once the message is fully encoded and written to the transport stream.
    public func send<Event: DebugAdapterEvent>(_ event: Event) {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            let eventID = self.nextMessageID()
            let message = EventMessage<Event>(seq: eventID, event: event)
            
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter event: \(eventID) \(Event.event)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter event: \(eventID) \(Event.event)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.configuration.loggingHandler?("DebugAdapter caught error while encoding event: \(error)")
            }
        }
    }
    
    /// Sends a raw event and continues once the message is fully encoded and written to the transport stream.
    public func send<Body>(event: String, body: Body?) where Body: Codable & Sendable {
        perform { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            
            let eventID = self.nextMessageID()
            let message = RawEventMessage(seq: eventID, event: event, body: body)
            
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(for: message) {
                        return "Sending DebugAdapter event: \(event)\n\(prettyString)"
                    }
                    else {
                        return "Sending DebugAdapter event: \(event)"
                    }
                }())
                
                try self.transport.write(data: data)
            }
            catch {
                self.configuration.loggingHandler?("DebugAdapter caught error while encoding event: \(error)")
            }
        }
    }
}

extension DebugAdapterConnection.IncomingRequest {
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequestWithRequiredResult>(_ requestType: Request.Type, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<Request.Result, Error>) -> Void) {
        let decoder = JSONDecoder()
        if let userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(DebugAdapterConnection.RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<Request.Result, Error>) -> Void = { [weak connection] result in
            switch result {
            case let .success(result):
                connection?.send(responseTo: request, requestID: message.seq, result: result)
            case let .failure(error):
                connection?.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequestWithOptionalResult>(_ requestType: Request.Type, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<Request.Result?, Error>) -> Void) {
        let decoder = JSONDecoder()
        if let userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(DebugAdapterConnection.RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<Request.Result?, Error>) -> Void = { [weak connection] result in
            switch result {
            case let .success(result):
                connection?.send(responseTo: request, requestID: message.seq, result: result)
            case let .failure(error):
                connection?.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequest>(_ requestType: Request.Type, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<(), Error>) -> Void) where Request.Result == Void {
        let decoder = JSONDecoder()
        if let userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(DebugAdapterConnection.RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<(), Error>) -> Void = { [weak connection] result in
            switch result {
            case .success:
                connection?.send(responseTo: request, requestID: message.seq)
            case let .failure(error):
                connection?.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    /// Decodes a raw request from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Arguments, ResultType>(_ argumentsType: Arguments.Type, resultType: ResultType.Type) throws -> (Arguments?, (Result<ResultType?, Error>) -> Void) where Arguments: Codable & Sendable, ResultType: Codable & Sendable {
        let message = try JSONDecoder().decode(DebugAdapterConnection.RawRequestMessage<Arguments>.self, from: data)
        let request = message.arguments
        
        let responseHandler: (Result<ResultType?, Error>) -> Void = { [weak connection] result in
            guard let connection else {
                return
            }
            
            switch result {
            case let .success(result):
                connection.send(responseToRequestID: message.seq, command: message.command, result: result)
            case let .failure(error):
                connection.send(responseToRequestID: message.seq, command: message.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    public func reject(throwing error: Error) {
        connection.send(responseToRequestID: seq, command: command, error: error)
    }
}

extension DebugAdapterConnection.IncomingEvent {
    /// Decodes an event of the specified type from the provided data.
    public func decode<Event: DebugAdapterEvent>(_ eventType: Event.Type, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> Event {
        let decoder = JSONDecoder()
        if let userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(DebugAdapterConnection.EventMessage<Event>.self, from: data)
        return try message.body ?? Event.init()
    }
    
    /// Decodes a raw event from the provided data.
    public func decode<Body>(_ bodyType: Body.Type, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> Body? where Body: Codable & Sendable {
        let decoder = JSONDecoder()
        if let userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(DebugAdapterConnection.RawEventMessage<Body>.self, from: data)
        return message.body
    }
    
    public func reject(throwing error: Error) {
        if let loggingHandler = connection.configuration.loggingHandler {
            connection.performOnMessageQueue {
                loggingHandler("Error caught while handling DebugAdapter event: \(event), \(error)")
            }
        }
    }
}

// MARK: - Transports

/// This protocol may be implemented to add new transport methods for communication.
public protocol DebugAdapterTransport {
    /// Invoked to set up the transport.
    func setUp(handler: DebugAdapterTransportHandler)
    
    /// Invoked to tear down the transport.
    func tearDown()
    
    /// Invoked to perform read requests for building messages off the transport.
    /// If the receiver's transport requires explicit reading of data, this method can be used to request data when it's needed.
    /// Otherwise, if the receiver simply reads data as it becomes available, it can provide an empty implementation of this method.
    func readData(minimumIncompleteLength: Int)
    
    /// Invoked to write data to the transport.
    func write(data: Data) throws
}

/// Provided to a transport in its `setUp()` method. Transports should invoke its methods as messages are read or if the transport terminates.
public protocol DebugAdapterTransportHandler {
    /// Should be invoked by the transport once communication is established.
    func didConnect()
    
    /// Should be invoked by the transport if communication is terminated unexpectedly.
    func didTerminate(withError error: Error?)
    
    /// Should be invoked by the transport as new data is read.
    /// The connection will automatically construct and dispatch messages as data is forwarded into its internal buffer using this method.
    func didRead(data: Data)
}

// MARK: - File Handles

/// A transport that uses file handles.
public final class DebugAdapterFileHandleTransport: DebugAdapterTransport {
    public let inputHandle: FileHandle
    public let outputHandle: FileHandle
    
    /// Creates a transport using specified file handles.
    public init(inputHandle: FileHandle, outputHandle: FileHandle) {
        self.inputHandle = inputHandle
        self.outputHandle = outputHandle
    }
    
    /// Creates a transport using stdin / stdout.
    convenience public init() {
        self.init(inputHandle: .standardInput, outputHandle: .standardOutput)
    }
    
    public func setUp(handler: DebugAdapterTransportHandler) {
        inputHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.count > 0 {
                handler.didRead(data: data)
            }
            else {
                // EOF
                handler.didTerminate(withError: nil)
            }
        }
        handler.didConnect()
    }
    
    public func tearDown() {
        inputHandle.readabilityHandler = nil
    }
    
    public func readData(minimumIncompleteLength: Int) {}
    
    public func write(data: Data) throws {
        try outputHandle.write(contentsOf: data)
    }
}
