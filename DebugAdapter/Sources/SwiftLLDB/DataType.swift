import CxxLLDB

public struct DataType: Sendable {
    let lldbType: lldb.SBType
    
    init?(_ lldbType: lldb.SBType) {
        guard lldbType.IsValid() else {
            return nil
        }
        self.lldbType = lldbType
    }
    
    init(unsafe lldbType: lldb.SBType) {
        self.lldbType = lldbType
    }
    
    public var byteSize: UInt64 {
        var lldbType = lldbType
        return lldbType.GetByteSize()
    }
}