import CxxLLDB

public struct Queue: Sendable {
    let lldbQueue: lldb.SBQueue
    
    init?(_ lldbQueue: lldb.SBQueue) {
        guard lldbQueue.IsValid() else {
            return nil
        }
        self.lldbQueue = lldbQueue
    }
}

extension Queue: Identifiable {
    public var id: Int {
        return Int(lldbQueue.GetQueueID())
    }
}

extension Queue {
    public var name: String? {
        return String(optionalCString: lldbQueue.GetName())
    }
    
    public var indexID: Int {
        return Int(lldbQueue.GetIndexID())
    }
    
    public struct Kind: RawRepresentable, Hashable {
        /// An unknown queue type.
        public static let unknown = Self(lldb.eQueueKindUnknown)
        /// A serial queue.
        public static let serial = Self(lldb.eQueueKindSerial)
        /// A concurrent queue.
        public static let concurrent = Self(lldb.eQueueKindConcurrent)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ value: lldb.QueueKind) {
            self.rawValue = Int(value.rawValue)
        }
    }
    
    public var kind: Kind {
        var lldbQueue = lldbQueue
        return Kind(lldbQueue.GetKind())
    }
}

extension Queue {
    public struct Threads: Sendable, RandomAccessCollection {
        let lldbQueue: lldb.SBQueue
        
        init(_ lldbQueue: lldb.SBQueue) {
            self.lldbQueue = lldbQueue
        }
        
        public var count: Int {
            var lldbQueue = lldbQueue
            return Int(lldbQueue.GetNumThreads())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Thread {
            var lldbQueue = lldbQueue
            return Thread(unsafe: lldbQueue.GetThreadAtIndex(UInt32(position)))
        }
    }
    
    public var threads: Threads { Threads(lldbQueue) }
}

