import CxxLLDB

public struct Instruction: Sendable {
    let lldbInstruction: lldb.SBInstruction
    
    init?(_ lldbInstruction: lldb.SBInstruction) {
        var lldbInstruction = lldbInstruction
        guard lldbInstruction.IsValid() else {
            return nil
        }
        self.lldbInstruction = lldbInstruction
    }
    
    init(unsafe lldbInstruction: lldb.SBInstruction) {
        self.lldbInstruction = lldbInstruction
    }
    
    public var address: Address? {
        var lldbInstruction = lldbInstruction
        return Address(lldbInstruction.GetAddress())
    }
    
    public func mnemonic(for target: Target) -> String? {
        var lldbInstruction = lldbInstruction
        return String(optionalCString: lldbInstruction.GetMnemonic(target.lldbTarget))
    }
    
    public func operands(for target: Target) -> String? {
        var lldbInstruction = lldbInstruction
        return String(optionalCString: lldbInstruction.GetOperands(target.lldbTarget))
    }
    
    public func comment(for target: Target) -> String? {
        var lldbInstruction = lldbInstruction
        return String(optionalCString: lldbInstruction.GetComment(target.lldbTarget))
    }
    
    public func data(for target: Target) -> DataBuffer? {
        var lldbInstruction = lldbInstruction
        return DataBuffer(lldbInstruction.GetData(target.lldbTarget))
    }
    
    public var byteSize: Int {
        var lldbInstruction = lldbInstruction
        return lldbInstruction.GetByteSize()
    }
    
    public var isBranch: Bool {
        var lldbInstruction = lldbInstruction
        return lldbInstruction.DoesBranch()
    }
    
    public var hasDelaySlot: Bool {
        var lldbInstruction = lldbInstruction
        return lldbInstruction.HasDelaySlot()
    }
    
    public var canSetBreakpoint: Bool {
        var lldbInstruction = lldbInstruction
        return lldbInstruction.CanSetBreakpoint()
    }
}
