import CxxLLDB

public struct CommandInterpreter: Sendable {
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
    
    public func handleCompletions(_ text: String, cursorPosition: Int, matchStart: Int, maxResults: Int? = nil) -> StringList {
        var lldbCommandInterpreter = lldbCommandInterpreter
        let maxCount = maxResults != nil ? Int32(maxResults!) : Int32.max
        var matches = lldb.SBStringList()
        _ = lldbCommandInterpreter.HandleCompletion(text, UInt32(cursorPosition), Int32(matchStart), maxCount, &matches)
        return StringList(matches)
    }
}

public struct CommandReturnObject: Sendable {
    let lldbCommandReturnObject: lldb.SBCommandReturnObject
    
    init(_ lldbCommandReturnObject: lldb.SBCommandReturnObject) {
        self.lldbCommandReturnObject = lldbCommandReturnObject
    }
    
    public var output: String? {
        var lldbCommandReturnObject = lldbCommandReturnObject
        return String(optionalCString: lldbCommandReturnObject.GetOutput())
    }
    
    public var error: String? {
        var lldbCommandReturnObject = lldbCommandReturnObject
        return String(optionalCString: lldbCommandReturnObject.GetError())
    }
}
