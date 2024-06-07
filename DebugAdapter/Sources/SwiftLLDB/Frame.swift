import CxxLLDB

public struct Frame: Equatable, Identifiable {
    let lldbFrame: lldb.SBFrame
    
    init(_ lldbFrame: lldb.SBFrame) {
        self.lldbFrame = lldbFrame
    }
    
    public static func == (lhs: Frame, rhs: Frame) -> Bool {
        return lhs.lldbFrame.IsEqual(rhs.lldbFrame)
    }
    
    public var id: Int {
        Int(lldbFrame.GetFrameID())
    }
    
    public var lineEntry: LineEntry {
        LineEntry(lldbFrame.GetLineEntry())
    }
    
    public var programCounter: UInt64 {
        lldbFrame.GetPC()
    }
    
    public var stackPointer: UInt64 {
        lldbFrame.GetSP()
    }
    
    public var framePointer: UInt64 {
        lldbFrame.GetFP()
    }
    
    public var function: Function? {
        let lldbFunction = lldbFrame.GetFunction()
        if lldbFunction.IsValid() {
            return Function(lldbFunction)
        }
        else {
            return nil
        }
    }
    
    public var isInlined: Bool {
        lldbFrame.IsInlined()
    }
    
    public var isArtificial: Bool {
        lldbFrame.IsArtificial()
    }
    
    public func evaluate(expression: String) throws -> Value {
        var lldbFrame = lldbFrame
        var lldbValue = lldbFrame.EvaluateExpression(expression)
        try lldbValue.GetError().throwOnFail()
        return Value(lldbValue)
    }
    
    public var registers: ValueList {
        var lldbFrame = lldbFrame
        return ValueList(lldbFrame.GetRegisters())
    }
    
    public func findRegister(withName name: String) -> Value? {
        var lldbFrame = lldbFrame
        var lldbValue = lldbFrame.FindRegister(name)
        if lldbValue.IsValid() {
            return Value(lldbValue)
        }
        else {
            return nil
        }
    }
    
    public enum VariableCategory: Hashable {
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
    
    public func findVariable(withName name: String) -> Value? {
        var lldbFrame = lldbFrame
        var lldbValue = lldbFrame.FindVariable(name)
        if lldbValue.IsValid() {
            return Value(lldbValue)
        }
        else {
            return nil
        }
    }
}