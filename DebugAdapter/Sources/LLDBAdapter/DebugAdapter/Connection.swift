import Foundation

/*
 *  An implementation of the Debug Adapter Protocol
 *  https://microsoft.github.io/debug-adapter-protocol/
 *
 *  How to use this:
 *  1. Add this file to your project.
 *  2. Create an instance of DebugAdapterConnection using the desired transport type.
 *  3. Set the connection's configuration to handle messages.
 *  3. Send messages using the `.send<X>(…)` methods.
 *
 *  This implementation includes transport classes for performing I/O over file handles and sockets,
 *  but other transports can be utilized by implementing the DebugAdapterTransport protocol.
 */

public class DebugAdapterConnection {
    /// The transport on which the connection will send and receive messages.
    public let transport: DebugAdapterTransport
    
    /// Options for customizing the behavior of a connection.
    public struct Configuration {
        /// The queue on which the configuration's block handlers will be invoked.
        /// If `nil` then the blocks will be invoked on an arbitrary queue.
        public var messageQueue: DispatchQueue?
        
        /// Invoked when the connection stops, after all pending messages have been dispatched.
        /// The optional error will be populated if the stop was caused by the underlying transport encountering an error.
        public var invalidationHandler: ((Error?) -> ())?
        
        /// Invoked to log details about what messages are sent and received from the receiver, as well as errors that may occur.
        public var loggingHandler: ((@autoclosure @escaping () -> (String)) -> ())?
        
        /// Invoked to handle requests.
        public var requestHandler: DebugAdapterRequestHandler?
        
        /// Invoked to handle events.
        public var eventHandler: DebugAdapterEventHandler?
        
        public init() {
        }
    }
    public private(set) var configuration = Configuration()
    
    public init(transport: DebugAdapterTransport, configuration: Configuration? = nil) {
        self.transport = transport
        if let configuration = configuration {
            self.configuration = configuration
        }
    }
    
    private let queueSpecific = DispatchSpecificKey<DebugAdapterConnection>()
    private lazy var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.panic.debugadapter-connection")
        queue.setSpecific(key: queueSpecific, value: self)
        return queue
    }()
    
    /// Enqueues a block on the receiver's internal serial dispatch queue.
    /// If the current queue is that serial queue the block will be executed immediately.
    public func perform(_ block: @escaping () -> ()) {
        if DispatchQueue.getSpecific(key: queueSpecific) === self {
            block()
        }
        else {
            queue.async(execute: block)
        }
    }
    
    private func performOnMessageQueue(_ queue: DispatchQueue? = nil, _ block: @escaping () -> ()) {
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
    private var startHandlers: [(Error?) -> ()] = []
    private var transportHandler: TransportHandler?
    
    /// Starts the connection, which also sets up the transport
    public func start(_ handler: ((Error?) -> ())? = nil) {
        perform { [weak self] in
            guard let self = self, !self.isRunning else {
                handler?(nil)
                return
            }
            
            self.isRunning = true
            
            let transportHandler = TransportHandler()
            transportHandler.connection = self
            self.transportHandler = transportHandler
            
            if let handler = handler {
                self.startHandlers.append(handler)
            }
            
            self.transport.setUp(handler: transportHandler)
        }
    }
    
    /// Stops the connection, which also stops the transport.
    /// If any requests are outstanding they are cancelled by throwing a cancellation error.
    /// If the connection is not running, this method does nothing.
    public func stop(error: Error? = nil) {
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            let configuration = self.configuration
            
            self.transport.tearDown()
            self.transportHandler = nil
            self.isRunning = false
            
            let startHandlers = self.startHandlers
            self.startHandlers = []
            for startHandler in startHandlers {
                startHandler(error)
            }
            
            self.performOnMessageQueue {
                configuration.invalidationHandler?(error)
            }
            
            // Answer any unreplied requests
            let pendingRequests = self.pendingRequests
            if pendingRequests.count > 0 {
                self.pendingRequests = [:]
                
                let requestError = error ?? MessageError.requestCancelled
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
            guard let self = self, self.isRunning else {
                return
            }
            
            let startHandlers = self.startHandlers
            self.startHandlers = []
            for startHandler in startHandlers {
                startHandler(nil)
            }
            
            self.readNextMessage()
        }
    }
    
    private func transportDidRead(data: Data) {
        perform { [weak self] in
            guard let self = self else {
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
            case .request(let seq, let command):
                try container.encode(seq, forKey: .seq)
                try container.encode("request", forKey: .type)
                try container.encode(command, forKey: .command)
                
            case .response(let seq, let requestSeq, let command, let success, let message):
                try container.encode(seq, forKey: .seq)
                try container.encode("response", forKey: .type)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(success, forKey: .success)
                try container.encode(message, forKey: .message)
                
            case .event(let seq, let event):
                try container.encode(seq, forKey: .seq)
                try container.encode("event", forKey: .type)
                try container.encode(event, forKey: .event)
            }
        }
    }
    
    public enum MessageError: LocalizedError {
        case requestFailed(String?, DebugAdapter.Message?)
        case unsupportedRequest(String)
        case requestCancelled
        
        public var errorDescription: String? {
            switch self {
            case .requestFailed(let message, _):
                return "Request failed: \(message ?? "")"
            case .unsupportedRequest(let request):
                return "An unsupported request was sent: \(request)"
            case .requestCancelled:
                return "The request was cancelled"
            }
        }
    }
    
    private static let CRLF = Data(bytes: [0x0d, 0x0a] as [UInt8], count: 2)
    
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
    
    private static func prettyPrintedString<T: Codable>(forObject object: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(object) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private static func prettyPrintedString(forJSONData data: Data) -> String? {
        guard let object = try? JSONDecoder().decode(JSONCodable.self, from: data) else {
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

    private enum ResponseRequiredResultMessage<Result: Codable>: Codable {
        case success(seq: Int, requestSeq: Int, command: String, result: Result)
        case failure(seq: Int, requestSeq: Int, command: String, message: String?, body: DebugAdapter.Message?)
        
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
                let message = try container.decodeIfPresent(String.self, forKey: .message)
                let body = try container.decodeIfPresent(DebugAdapter.Message.self, forKey: .body)
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, message: message, body: body)
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
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, message: let message, body: let body):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encode(message, forKey: .message)
                try container.encode(body, forKey: .body)
            }
        }
    }
    
    private enum ResponseOptionalResultMessage<Result: Codable>: Codable {
        case success(seq: Int, requestSeq: Int, command: String, result: Result?)
        case failure(seq: Int, requestSeq: Int, command: String, message: String?, body: DebugAdapter.Message?)
        
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
                let message = try container.decodeIfPresent(String.self, forKey: .message)
                let body = try container.decodeIfPresent(DebugAdapter.Message.self, forKey: .body)
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, message: message, body: body)
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
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, message: let message, body: let body):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encode(message, forKey: .message)
                try container.encode(body, forKey: .body)
            }
        }
    }

    private enum ResponseVoidMessage: Codable {
        case success(seq: Int, requestSeq: Int, command: String)
        case failure(seq: Int, requestSeq: Int, command: String, message: String?, body: DebugAdapter.Message?)
        
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
                let message = try container.decodeIfPresent(String.self, forKey: .message)
                let body = try container.decodeIfPresent(DebugAdapter.Message.self, forKey: .body)
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, message: message, body: body)
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
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, message: let message, body: let body):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encode(message, forKey: .message)
                try container.encode(body, forKey: .body)
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
    
    private struct RawRequestMessage: Codable {
        let seq: Int
        let command: String
        let arguments: JSONCodable?
        
        init(seq: Int, command: String, arguments: JSONCodable?) {
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
            arguments = try container.decodeIfPresent(JSONCodable.self, forKey: .arguments)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("request", forKey: .type)
            try container.encode(command, forKey: .command)
            try container.encode(arguments, forKey: .arguments)
        }
    }
    
    private enum RawResponseMessage: Codable {
        case success(seq: Int, requestSeq: Int, command: String, result: JSONCodable?)
        case failure(seq: Int, requestSeq: Int, command: String, message: String?, body: DebugAdapter.Message?)
        
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
                let result = try container.decodeIfPresent(JSONCodable.self, forKey: .body)
                self = .success(seq: seq, requestSeq: requestSeq, command: command, result: result)
            }
            else {
                let message = try container.decodeIfPresent(String.self, forKey: .message)
                let body = try container.decodeIfPresent(DebugAdapter.Message.self, forKey: .body)
                self = .failure(seq: seq, requestSeq: requestSeq, command: command, message: message, body: body)
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
                
            case .failure(seq: let seq, requestSeq: let requestSeq, command: let command, message: let message, body: let body):
                try container.encode(seq, forKey: .seq)
                try container.encode(requestSeq, forKey: .requestSeq)
                try container.encode(command, forKey: .command)
                try container.encode(false, forKey: .success)
                try container.encode(message, forKey: .message)
                try container.encode(body, forKey: .body)
            }
        }
    }
    
    private struct RawEventMessage: Codable {
        let seq: Int
        let event: String
        let body: JSONCodable?
        
        init(seq: Int, event: String, body: JSONCodable?) {
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
            body = try container.decodeIfPresent(JSONCodable.self, forKey: .body)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(seq, forKey: .seq)
            try container.encode("event", forKey: .type)
            try container.encode(event, forKey: .event)
            try container.encode(body, forKey: .body)
        }
    }
    
    private func readNextMessage() {
        transport.readData(to: Self.CRLF, timeout: -1)
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
        else {
            if additionalRequiredLength > 0 {
                transport.readData(toLength: additionalRequiredLength, timeout: -1)
            }
            else {
                readNextMessage()
            }
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
            if let CRLFRange = CRLFRange {
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
            case .request(let seq, let command):
                if let handler = configuration.requestHandler {
                    self.performOnMessageQueue { [weak self] in
                        guard let self = self, self.isRunning else {
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
                        
                        do {
                            try handler.handleRequest(forCommand: command, data: contentData, connection: self)
                        }
                        catch {
                            self.send(responseToRequestID: seq, command: command, error: error)
                        }
                    }
                }
                else {
                    // No handler set; Send method not supported.
                    let responseID = self.nextMessageID()
                    let response = RawResponseMessage.failure(seq: responseID, requestSeq: seq, command: command, message: "Method is not supported: \(command)", body: nil)
                    
                    do {
                        let responseData = try Self.data(forMessage: response)
                        try transport.write(data: responseData)
                    }
                    catch {
                        if let loggingHandler = configuration.loggingHandler {
                            self.performOnMessageQueue {
                                loggingHandler("DebugAdapter could not encode error response for request \(seq) \(command): \(error)")
                            }
                        }
                    }
                }
                
            case .response(_, let requestSeq, let command, _, _):
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
                
            case .event(_, let eventName):
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
                        
                        handler.handleEvent(eventName, data: contentData, connection: self)
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
    
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequestWithRequiredResult>(_ requestType: Request.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<Request.Result, Error>) -> ()) {
        let decoder = JSONDecoder()
        if let userInfo = userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<Request.Result, Error>) -> () = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let result):
                self.send(responseTo: request, requestID: message.seq, result: result)
            case .failure(let error):
                self.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequestWithOptionalResult>(_ requestType: Request.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<Request.Result?, Error>) -> ()) {
        let decoder = JSONDecoder()
        if let userInfo = userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<Request.Result?, Error>) -> () = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let result):
                self.send(responseTo: request, requestID: message.seq, result: result)
            case .failure(let error):
                self.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    private func send<Request: DebugAdapterRequestWithRequiredResult>(responseTo request: Request, requestID: Int, result: Request.Result) {
        perform { [weak self] in
            guard let self = self, self.isRunning else {
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
            guard let self = self, self.isRunning else {
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
    
    /// Decodes a request of the specified type from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply<Request: DebugAdapterRequest>(_ requestType: Request.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> (Request, (Result<(), Error>) -> ()) where Request.Result == Void {
        let decoder = JSONDecoder()
        if let userInfo = userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(RequestMessage<Request>.self, from: data)
        let request = try message.arguments ?? Request.init()
        
        let responseHandler: (Result<(), Error>) -> () = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                self.send(responseTo: request, requestID: message.seq)
            case .failure(let error):
                self.send(responseToRequestID: message.seq, command: Request.command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    private func send<Request: DebugAdapterRequest>(responseTo request: Request, requestID: Int) where Request.Result == Void {
        perform { [weak self] in
            guard let self = self, self.isRunning else {
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
    
    /// Decodes a raw request from the provided data, returning the request and a reply handler
    /// which should be invoked when handling of the request completes.
    public func decodeForReply(command: String, from data: Data) throws -> (JSONCodable?, (Result<JSONCodable?, Error>) -> ()) {
        let message = try JSONDecoder().decode(RawRequestMessage.self, from: data)
        let request = message.arguments
        
        let responseHandler: (Result<JSONCodable?, Error>) -> () = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let result):
                self.send(responseToRequestID: message.seq, command: command, result: result)
            case .failure(let error):
                self.send(responseToRequestID: message.seq, command: command, error: error)
            }
        }
        return (request, responseHandler)
    }
    
    private func send(responseToRequestID requestID: Int, command: String, result: JSONCodable?) {
        perform { [weak self] in
            guard let self = self, self.isRunning else {
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
            guard let self = self, self.isRunning else {
                return
            }
            
            let responseID = self.nextMessageID()
            let errorString = Self.errorString(forError: error)
            let response = RawResponseMessage.failure(seq: responseID, requestSeq: requestID, command: command, message: errorString, body: nil)
            
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
    
    /// Decodes an event of the specified type from the provided data.
    public func decode<Event: DebugAdapterEvent>(_ eventType: Event.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> Event {
        let decoder = JSONDecoder()
        if let userInfo = userInfo {
            decoder.userInfo = userInfo
        }
        
        let message = try decoder.decode(EventMessage<Event>.self, from: data)
        return try message.body ?? Event.init()
    }
    
    /// Decodes a raw event from the provided data.
    public func decode(event: String, from data: Data) throws -> JSONCodable? {
        let message = try JSONDecoder().decode(RawEventMessage.self, from: data)
        return message.body
    }
    
    private static func errorString(forError error: Error) -> String {
        if let error = error as? LocalizedError {
            var components: [String] = []
            
            if let errorDescription = error.errorDescription {
                components.append(errorDescription)
            }
            if let recoverySuggestion = error.recoverySuggestion {
                components.append(recoverySuggestion)
            }
            
            if components.count == 0 {
                components.append(error.localizedDescription)
            }
            
            return components.joined(separator: "\n\n")
        }
        else {
            return "\(error.localizedDescription)"
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
    
    /// If set to YES, then for any requests whose progress objects are cancelled
    /// the connection will automatically send a corresponding cancel request.
    public private(set) var supportsCancelRequest = false
    
    public func setSupportsCancelRequest(_ flag: Bool) {
        supportsCancelRequest = flag
    }
    
    public class CancellationToken {
        fileprivate private(set) var isCancelled = false
        private weak var connection: DebugAdapterConnection?
        private var cancelHandlers: [() -> ()] = []
        
        fileprivate init(connection: DebugAdapterConnection) {
            self.connection = connection
        }
        
        fileprivate func onCancel(_ block: @escaping () -> ()) {
            connection?.perform { [weak self] in
                self?.cancelHandlers.append(block)
            }
        }
        
        public func cancel() {
            connection?.perform { [weak self] in
                guard let self = self, !self.isCancelled else {
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
            guard let self = self, self.isRunning else {
                return
            }
            
            if let (method, queue, handler) = self.pendingRequests[requestID] {
                self.pendingRequests[requestID] = nil
                
                self.performOnMessageQueue(queue) {
                    if let loggingHandler = self.configuration.loggingHandler {
                        loggingHandler("Cancelling DebugAdapter request: \(requestID) \(method)")
                    }
                    
                    handler(.failure(MessageError.requestCancelled))
                }
                
                self.send(CancelRequest(requestId: requestID)) { _ in }
            }
        }
    }
    
    private var pendingRequests: [Int: (String, DispatchQueue?, (Result<Data, Error>) -> ())] = [:]
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequestWithRequiredResult>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<Request.Result, Error>) -> ()) -> CancellationToken {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> () = { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseRequiredResultMessage<Request.Result>.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result))
                        case .failure(_, _, _, message: let message, body: let body):
                            replyHandler(.failure(MessageError.requestFailed(message, body)))
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
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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
    @available(macOS 10.15, *)
    public func send<Request: DebugAdapterRequestWithRequiredResult>(_ request: Request) async throws -> Request.Result {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequestWithOptionalResult>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<Request.Result?, Error>) -> ()) -> CancellationToken {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> () = { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseOptionalResultMessage<Request.Result>.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result))
                        case .failure(_, _, _, message: let message, body: let body):
                            replyHandler(.failure(MessageError.requestFailed(message, body)))
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
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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
    @available(macOS 10.15, *)
    public func send<Request: DebugAdapterRequestWithOptionalResult>(_ request: Request) async throws -> Request.Result? {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a request and returns when either a response is returned or the request is cancelled.
    @discardableResult public func send<Request: DebugAdapterRequest>(_ request: Request, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<(), Error>) -> ()) -> CancellationToken where Request.Result == Void {
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> () = { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(ResponseVoidMessage.self, from: data)
                        
                        switch response {
                        case .success(_, _, _):
                            replyHandler(.success(()))
                        case .failure(_, _, _, message: let message, body: let body):
                            replyHandler(.failure(MessageError.requestFailed(message, body)))
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
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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
    @available(macOS 10.15, *)
    public func send<Request: DebugAdapterRequest>(_ request: Request) async throws where Request.Result == Void {
        return try await withUnsafeThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case .success(_):
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Sends a raw request and returns when either a response is returned or the request is cancelled.
    /// This method will throw an error if the provided arguments are not JSON-serializable.
    @discardableResult public func send(command: String, arguments: Any?, replyOn queue: DispatchQueue? = nil, replyHandler: @escaping (Result<Any?, Error>) -> ()) throws -> CancellationToken {
        let args = try JSONCodable(withJSONValue: arguments)
        let token = CancellationToken(connection: self)
        
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            if token.isCancelled {
                return
            }
            
            let messageID = self.nextMessageID()
            
            token.onCancel { [weak self] in
                self?.cancel(requestID: messageID)
            }
            
            let dataHandler: (Result<Data, Error>) -> () = { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(RawResponseMessage.self, from: data)
                        
                        switch response {
                        case .success(_, _, _, result: let result):
                            replyHandler(.success(result?.JSONValue))
                        case .failure(_, _, _, message: let message, body: let body):
                            replyHandler(.failure(MessageError.requestFailed(message, body)))
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
            
            let message = RawRequestMessage(seq: messageID, command: command, arguments: args)
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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
    @available(macOS 10.15, *)
    public func send(request command: String, arguments: Any?) async throws -> Any? {
        return try await withUnsafeThrowingContinuation { continuation in
            do {
                try send(command: command, arguments: arguments) { result in
                    switch result {
                    case .success(let result):
                        continuation.resume(returning: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sends an event and continues once the message is fully encoded and written to the transport stream.
    public func send<Event: DebugAdapterEvent>(_ event: Event) {
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            let eventID = self.nextMessageID()
            let message = EventMessage<Event>(seq: eventID, event: event)
            
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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
    /// This method will throw an error if the provided parameters are not JSON-serializable.
    public func send(event: String, body: Any?) throws {
        let bodyJSON = try JSONCodable(withJSONValue: body)
        
        perform { [weak self] in
            guard let self = self, self.isRunning else {
                return
            }
            
            let eventID = self.nextMessageID()
            let message = RawEventMessage(seq: eventID, event: event, body: bodyJSON)
            
            do {
                let data = try Self.data(forMessage: message)
                
                self.configuration.loggingHandler?({
                    if let prettyString = Self.prettyPrintedString(forObject: message) {
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

// MARK: - Transports

/// This protocol may be implemented to add new transport methods for communication.
public protocol DebugAdapterTransport {
    /// Invoked to set up the transport.
    func setUp(handler: DebugAdapterTransportHandler)
    
    /// Invoked to tear down the transport.
    func tearDown()
    
    /// Invoked to perform read requests for building messages off the transport.
    /// If the receiver's transport requires explicit reading of data, this method can be used to request data when it's needed
    /// Otherwise, if the receiver simply reads data as it becomes available, it can ignore implementation of this method.
    func readData(toLength length: Int, timeout: TimeInterval)
    
    /// Invoked to perform read requests for building messages off the transport.
    /// If the receiver's transport requires explicit reading of data, this method can be used to request data when it's needed
    /// Otherwise, if the receiver simply reads data as it becomes available, it can ignore implementation of this method.
    func readData(to data: Data, timeout: TimeInterval)
    
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

/// A transport subclass that uses file handles
public final class DebugAdapterFileHandleTransport: DebugAdapterTransport {
    public private(set) var inputHandle: FileHandle
    public private(set) var outputHandle: FileHandle
    
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
    
    public func readData(to data: Data, timeout: TimeInterval) {
    }
    
    public func readData(toLength length: Int, timeout: TimeInterval) {
    }
    
    public func tearDown() {
        inputHandle.readabilityHandler = nil
    }
    
    public func write(data: Data) throws {
        try outputHandle.write(contentsOf: data)
    }
}
