import CxxLLDB

public struct MemoryRegionInfo: Sendable {
    let lldbInfo: lldb.SBMemoryRegionInfo
    
    init(_ lldbInfo: lldb.SBMemoryRegionInfo) {
        self.lldbInfo = lldbInfo
    }
    
    public var range: Range<UInt64> {
        var lldbInfo = lldbInfo
        return lldbInfo.GetRegionBase() ..< lldbInfo.GetRegionEnd()
    }
    
    public var isReadable: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.IsReadable()
    }
    
    public var isWritable: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.IsWritable()
    }
    
    public var isExecutable: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.IsExecutable()
    }
    
    public var isMapped: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.IsMapped()
    }
    
    public var name: String? {
        var lldbInfo = lldbInfo
        return String(optionalCString: lldbInfo.GetName())
    }
}
