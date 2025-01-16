import CxxLLDB

public struct Frame: Sendable {
    let lldbFrame: lldb.SBFrame
    
    init?(_ lldbFrame: lldb.SBFrame) {
        guard lldbFrame.IsValid() else {
            return nil
        }
        self.lldbFrame = lldbFrame
    }
    
    init(unsafe lldbFrame: lldb.SBFrame) {
        self.lldbFrame = lldbFrame
    }
}

extension Frame: Equatable {
    public static func == (lhs: Frame, rhs: Frame) -> Bool {
        return lhs.lldbFrame.IsEqual(rhs.lldbFrame)
    }
}

extension Frame: Identifiable {
    public var id: Int {
        return Int(lldbFrame.GetFrameID())
    }
}

extension Frame {
    public var displayFunctionName: String? {
        var lldbFrame = lldbFrame
        return String(optionalCString: lldbFrame.GetDisplayFunctionName())
    }
    
    public var lineEntry: LineEntry? {
        return LineEntry(lldbFrame.GetLineEntry())
    }
    
    public var programCounter: UInt64? {
        let pc = lldbFrame.GetPC()
        guard pc != LLDB_INVALID_ADDRESS else {
            return nil
        }
        return pc
    }
    
    public var stackPointer: UInt64 {
        return lldbFrame.GetSP()
    }
    
    public var framePointer: UInt64 {
        return lldbFrame.GetFP()
    }
    
    public var function: Function? {
        return Function(lldbFrame.GetFunction())
    }
    
    public var isInlined: Bool {
        return lldbFrame.IsInlined()
    }
    
    public var isArtificial: Bool {
        return lldbFrame.IsArtificial()
    }
}

extension Frame {
    public func evaluate(expression: String) throws -> Value {
        var lldbFrame = lldbFrame
        var lldbValue = lldbFrame.EvaluateExpression(expression)
        try lldbValue.GetError().throwOnFail()
        return Value(unsafe: lldbValue)
    }
}

extension Frame {
    public var registers: ValueList {
        var lldbFrame = lldbFrame
        return ValueList(lldbFrame.GetRegisters())
    }
    
    public func findRegister(withName name: String) -> Value? {
        var lldbFrame = lldbFrame
        let lldbValue = lldbFrame.FindRegister(name)
        return Value(lldbValue)
    }
}

extension Frame {
    public enum VariableCategory: Sendable, Hashable {
        case arguments
        case locals
        case statics
    }
    
    public func variables(for categories: Set<VariableCategory>, inScopeOnly: Bool) -> ValueList {
        var lldbFrame = lldbFrame
        return ValueList(lldbFrame.GetVariables(
            categories.contains(.arguments),
            categories.contains(.locals),
            categories.contains(.statics),
            inScopeOnly))
    }
    
    public func findVariable(named name: String) -> Value? {
        var lldbFrame = lldbFrame
        let lldbValue = lldbFrame.FindVariable(name)
        return Value(lldbValue)
    }
}