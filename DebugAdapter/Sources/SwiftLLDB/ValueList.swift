import CxxLLDB

public struct ValueList: RandomAccessCollection {
    let lldbValueList: lldb.SBValueList
    
    init(_ lldbValueList: lldb.SBValueList) {
        self.lldbValueList = lldbValueList
    }
    
    public var count: Int {
        Int(lldbValueList.GetSize())
    }
    
    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { count }
    @inlinable public func index(before i: Int) -> Int { i - 1 }
    @inlinable public func index(after i: Int) -> Int { i + 1 }
    
    public subscript(position: Int) -> Value {
        Value(lldbValueList.GetValueAtIndex(UInt32(position)))
    }
    
    public func firstValue(withName name: String) -> Value? {
        var lldbValue = lldbValueList.GetFirstValueByName(name)
        if lldbValue.IsValid() {
            return Value(lldbValue)
        }
        else {
            return nil
        }
    }
}
