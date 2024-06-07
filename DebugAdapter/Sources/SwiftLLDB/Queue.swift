import CxxLLDB

public struct Queue: Identifiable {
    let lldbQueue: lldb.SBQueue
    
    init(_ lldbQueue: lldb.SBQueue) {
        self.lldbQueue = lldbQueue
    }
    
    public var id: Int {
        Int(lldbQueue.GetQueueID())
    }
    
    public var name: String? {
        if let str = lldbQueue.GetName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var indexID: Int {
        Int(lldbQueue.GetIndexID())
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
    
    public struct Threads: RandomAccessCollection {
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
        @inlinable public func index(before i: Int) -> Int { i - 1 }
        @inlinable public func index(after i: Int) -> Int { i + 1 }
        
        public subscript(position: Int) -> Thread {
            var lldbQueue = lldbQueue
            return Thread(lldbQueue.GetThreadAtIndex(UInt32(position)))
        }
    }
    public var threads: Threads { Threads(lldbQueue) }
}

