import CxxLLDB

public struct ValueList: Sendable, RandomAccessCollection {
    let lldbValueList: lldb.SBValueList
    
    init(_ lldbValueList: lldb.SBValueList) {
        self.lldbValueList = lldbValueList
    }
    
    public var count: Int { Int(lldbValueList.GetSize()) }
    
    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { count }
    
    public subscript(position: Int) -> Value {
        return Value(unsafe: lldbValueList.GetValueAtIndex(UInt32(position)))
    }
    
    public func first(named name: String) -> Value? {
        return Value(lldbValueList.GetFirstValueByName(name))
    }
}
