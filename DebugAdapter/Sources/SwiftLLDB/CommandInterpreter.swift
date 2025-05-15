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
    
    public func handleCompletions(_ text: String, cursorPosition: Int, matchStart: Int = 0, maxResults: Int = 100) -> (matches: StringList, descriptions: StringList) {
        var lldbCommandInterpreter = lldbCommandInterpreter
        var matches = lldb.SBStringList()
        var descriptions = lldb.SBStringList()
        _ = lldbCommandInterpreter.HandleCompletionWithDescriptions(text, UInt32(cursorPosition), Int32(matchStart), Int32(maxResults), &matches, &descriptions)
        return (StringList(matches), StringList(descriptions))
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
