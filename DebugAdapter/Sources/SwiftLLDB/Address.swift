import CxxLLDB

public struct Address: Sendable {
    let lldbAddress: lldb.SBAddress
    
    init?(_ lldbAddress: lldb.SBAddress) {
        guard lldbAddress.IsValid() else {
            return nil
        }
        self.lldbAddress = lldbAddress
    }
    
    init(unsafe lldbAddress: lldb.SBAddress) {
        self.lldbAddress = lldbAddress
    }
    
    public init?(at addr: UInt64, in target: Target) {
        var lldbTarget = target.lldbTarget
        let lldbAddress = lldb.SBAddress(addr, &lldbTarget)
        self.init(lldbAddress)
    }
    
    public var lineEntry: LineEntry? {
        var lldbAddress = lldbAddress
        return LineEntry(lldbAddress.GetLineEntry())
    }
    
    public var fileAddress: UInt64 {
        return lldbAddress.GetFileAddress()
    }
    
    public func loadAddress(for target: Target) -> UInt64 {
        return lldbAddress.GetLoadAddress(target.lldbTarget)
    }
    
    public var offset: UInt64 {
        var lldbAddress = lldbAddress
        return lldbAddress.GetOffset()
    }
    
    public var function: Function? {
        var lldbAddress = lldbAddress
        return Function(lldbAddress.GetFunction())
    }
    
    public var symbol: Symbol? {
        var lldbAddress = lldbAddress
        return Symbol(lldbAddress.GetSymbol())
    }
}

extension Address: Equatable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.lldbAddress == rhs.lldbAddress
    }
}
