import CxxLLDB

public struct InstructionList: Sendable {
    nonisolated(unsafe) let lldbInstructionList: lldb.SBInstructionList
    
    init?(_ lldbInstructionList: lldb.SBInstructionList) {
        guard lldbInstructionList.IsValid() else {
            return nil
        }
        self.lldbInstructionList = lldbInstructionList
    }
    
    init(unsafe lldbInstructionList: lldb.SBInstructionList) {
        self.lldbInstructionList = lldbInstructionList
    }
}

extension InstructionList: RandomAccessCollection {
    public var count: Int {
        var lldbInstructionList = lldbInstructionList
        return lldbInstructionList.GetSize()
    }
    
    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { count }
    
    public subscript(position: Int) -> Instruction {
        var lldbInstructionList = lldbInstructionList
        return Instruction(unsafe: lldbInstructionList.GetInstructionAtIndex(UInt32(position)))
    }
}
