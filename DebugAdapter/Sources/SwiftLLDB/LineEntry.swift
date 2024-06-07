import CxxLLDB

public struct LineEntry: Equatable {
    let lldbLineEntry: lldb.SBLineEntry
    
    init(_ lldbLineEntry: lldb.SBLineEntry) {
        self.lldbLineEntry = lldbLineEntry
    }
    
    public static func == (lhs: LineEntry, rhs: LineEntry) -> Bool {
        return lhs.lldbLineEntry == rhs.lldbLineEntry
    }
    
    public var line: Int {
        Int(lldbLineEntry.GetLine())
    }
    
    public var column: Int {
        Int(lldbLineEntry.GetColumn())
    }
    
    public var fileSpec: FileSpec {
        FileSpec(lldbLineEntry.GetFileSpec())
    }
}
