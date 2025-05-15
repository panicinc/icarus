import CxxLLDB

public struct StringList: Sendable, RandomAccessCollection {
    let lldbStringList: lldb.SBStringList
    
    init(_ lldbStringList: lldb.SBStringList) {
        self.lldbStringList = lldbStringList
    }
    
    public var count: Int { Int(lldbStringList.GetSize()) }
    
    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { count }
    
    public subscript(position: Int) -> String {
        return String(cString: lldbStringList.GetStringAtIndex(position))
    }
}
