import CxxLLDB

public struct CommandInterpreter {
    let lldbCommandInterpreter: lldb.SBCommandInterpreter
    
    init(_ lldbCommandInterpreter: lldb.SBCommandInterpreter) {
        self.lldbCommandInterpreter = lldbCommandInterpreter
    }
    
    public func handleCommand(_ command: String, context: ExecutionContext, addToHistory: Bool = false) throws -> CommandReturnObject {
        var lldbCommandInterpreter = lldbCommandInterpreter
        var result = lldb.SBCommandReturnObject()
        var lldbContext = context.lldbExecutionContext
        lldbCommandInterpreter.HandleCommand(command, &lldbContext, &result, addToHistory)
        if result.Succeeded() {
            return CommandReturnObject(result)
        }
        else {
            var error = lldb.SBError()
            if let str = result.GetError() {
                error.SetErrorString(str)
            }
            throw LLDBError(error)
        }
    }
    
    public func handleCompletions(_ text: String, cursorPosition: Int, matchStart: Int, maxCount: Int? = nil) -> [String] {
        var lldbCommandInterpreter = lldbCommandInterpreter
        var matches = lldb.SBStringList()
        let maxCount = maxCount != nil ? Int32(maxCount!) : Int32.max
        if lldbCommandInterpreter.HandleCompletion(text, UInt32(cursorPosition), Int32(matchStart), maxCount, &matches) > 0 {
            let count = Int(matches.GetSize())
            return (0 ..< count).compactMap { idx in
                if let str = matches.GetStringAtIndex(idx) {
                    return String(cString: str)
                }
                else {
                    return nil
                }
            }
        }
        else {
            return []
        }
    }
}

public struct CommandReturnObject {
    let lldbCommandReturnObject: lldb.SBCommandReturnObject
    
    init(_ lldbCommandReturnObject: lldb.SBCommandReturnObject) {
        self.lldbCommandReturnObject = lldbCommandReturnObject
    }
    
    public var output: String? {
        var lldbCommandReturnObject = lldbCommandReturnObject
        if let str = lldbCommandReturnObject.GetOutput() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var error: String? {
        var lldbCommandReturnObject = lldbCommandReturnObject
        if let str = lldbCommandReturnObject.GetError() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
}
