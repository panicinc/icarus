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
    
    public var startAddress: Address? {
        return Address(lldbLineEntry.GetStartAddress())
    }
    
    public var endAddress: Address? {
        return Address(lldbLineEntry.GetEndAddress())
    }
    
    // `GetSameLineContiguousAddressRangeEnd` is not yet available in Swift's
    // copy of LLDB as of Xcode 16.2.
    // public func sameLineContiguousAddressRangeEnd(includingInlinedFunctions: Bool) -> Address? {
    //     return Address(lldbLineEntry.GetSameLineContiguousAddressRangeEnd(includingInlinedFunctions))
    // }
    
    public var line: Int? {
        let line = lldbLineEntry.GetLine()
        guard line != LLDB_INVALID_LINE_NUMBER else {
            return nil
        }
        return Int(line)
    }
    
    public var column: Int? {
        let column = lldbLineEntry.GetColumn()
        guard column != LLDB_INVALID_COLUMN_NUMBER else {
            return nil
        }
        return Int(column)
    }
    
    public var fileSpec: FileSpec? {
        return FileSpec(lldbLineEntry.GetFileSpec())
    }
}
