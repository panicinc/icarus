import CxxLLDB

public struct LineEntry: Sendable, Equatable {
    let lldbLineEntry: lldb.SBLineEntry
    
    init?(_ lldbLineEntry: lldb.SBLineEntry) {
        guard lldbLineEntry.IsValid() else {
            return nil
        }
        self.lldbLineEntry = lldbLineEntry
    }
    
    public static func == (lhs: LineEntry, rhs: LineEntry) -> Bool {
        return lhs.lldbLineEntry == rhs.lldbLineEntry
    }
    
    public var line: Int? {
        let line = lldbLineEntry.GetLine()
        guard line != LLDB_INVALID_LINE_NUMBER else {
            return nil
        }
        return Int(line)
    }
    
    public var column: Int {
        return Int(lldbLineEntry.GetColumn())
    }
    
    public var fileSpec: FileSpec? {
        return FileSpec(lldbLineEntry.GetFileSpec())
    }
}
