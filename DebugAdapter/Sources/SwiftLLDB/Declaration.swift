import CxxLLDB

public struct Declaration: Sendable {
    let lldbDeclaration: lldb.SBDeclaration
    
    init?(_ lldbDeclaration: lldb.SBDeclaration) {
        guard lldbDeclaration.IsValid() else {
            return nil
        }
        self.lldbDeclaration = lldbDeclaration
    }
    
    init(unsafe lldbDeclaration: lldb.SBDeclaration) {
        self.lldbDeclaration = lldbDeclaration
    }
    
    public var fileSpec: FileSpec? {
        return FileSpec(lldbDeclaration.GetFileSpec())
    }
    
    public var line: Int? {
        let line = lldbDeclaration.GetLine()
        guard line != LLDB_INVALID_LINE_NUMBER else {
            return nil
        }
        return Int(line)
    }
    
    public var column: Int? {
        let column = lldbDeclaration.GetColumn()
        guard column != LLDB_INVALID_COLUMN_NUMBER else {
            return nil
        }
        return Int(column)
    }
}

extension Declaration: Equatable {
    public static func == (lhs: Declaration, rhs: Declaration) -> Bool {
        return lhs.lldbDeclaration == rhs.lldbDeclaration
    }
}
