import CxxLLDB

public struct Function: Equatable {
    let lldbFunction: lldb.SBFunction
    
    init(_ lldbFunction: lldb.SBFunction) {
        self.lldbFunction = lldbFunction
    }
    
    public static func == (lhs: Function, rhs: Function) -> Bool {
        return lhs.lldbFunction == rhs.lldbFunction
    }
    
    public var name: String? {
        if let str = lldbFunction.GetName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var displayName: String? {
        if let str = lldbFunction.GetDisplayName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var mangledName: String? {
        if let str = lldbFunction.GetMangledName() {
            return String(cString: str)
        }
        else {
            return nil
        }
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
