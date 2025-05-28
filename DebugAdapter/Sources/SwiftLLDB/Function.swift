import CxxLLDB

public struct Function: Sendable {
    nonisolated(unsafe) let lldbFunction: lldb.SBFunction
    
    init?(_ lldbFunction: lldb.SBFunction) {
        guard lldbFunction.IsValid() else {
            return nil
        }
        self.lldbFunction = lldbFunction
    }
    
    init(unsafe lldbFunction: lldb.SBFunction) {
        self.lldbFunction = lldbFunction
    }
}

extension Function: Equatable {
    public static func == (lhs: Function, rhs: Function) -> Bool {
        return lhs.lldbFunction == rhs.lldbFunction
    }
}

extension Function {
    public var name: String? {
        return String(optionalCString: lldbFunction.GetName())
    }
    
    public var displayName: String? {
        return String(optionalCString: lldbFunction.GetDisplayName())
    }
    
    public var mangledName: String? {
        return String(optionalCString: lldbFunction.GetMangledName())
    }
    
    public var isOptimized: Bool {
        var lldbFunction = lldbFunction
        return lldbFunction.GetIsOptimized()
    }
    
    public var language: Language {
        var lldbFunction = lldbFunction
        return Language(lldbFunction.GetLanguage())
    }
}
