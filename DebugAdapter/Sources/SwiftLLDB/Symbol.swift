import CxxLLDB

public struct Symbol: Sendable {
    nonisolated(unsafe) let lldbSymbol: lldb.SBSymbol
    
    init?(_ lldbSymbol: lldb.SBSymbol) {
        guard lldbSymbol.IsValid() else {
            return nil
        }
        self.lldbSymbol = lldbSymbol
    }
    
    init(unsafe lldbSymbol: lldb.SBSymbol) {
        self.lldbSymbol = lldbSymbol
    }
    
    public var name: String? {
        return String(optionalCString: lldbSymbol.GetName())
    }
    
    public var displayName: String? {
        return String(optionalCString: lldbSymbol.GetDisplayName())
    }
    
    public var mangledName: String? {
        return String(optionalCString: lldbSymbol.GetMangledName())
    }
    
    public var startAddress: Address? {
        var lldbSymbol = lldbSymbol
        return Address(lldbSymbol.GetStartAddress())
    }
    
    public var endAddress: Address? {
        var lldbSymbol = lldbSymbol
        return Address(lldbSymbol.GetEndAddress())
    }
    
    public var size: UInt64 {
        var lldbSymbol = lldbSymbol
        return lldbSymbol.GetSize()
    }
}