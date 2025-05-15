import CxxLLDB

public struct FileSpec: Sendable {
    let lldbFileSpec: lldb.SBFileSpec
    
    init?(_ lldbFileSpec: lldb.SBFileSpec) {
        guard lldbFileSpec.IsValid() else {
            return nil
        }
        self.lldbFileSpec = lldbFileSpec
    }
    
    public var directory: String {
        return String(cString: lldbFileSpec.GetDirectory())
    }
    
    public var filename: String {
        return String(cString: lldbFileSpec.GetFilename())
    }
    
    public var path: String {
        return "\(directory)/\(filename)"
    }
}

extension FileSpec: Equatable {
    public static func == (lhs: FileSpec, rhs: FileSpec) -> Bool {
        return lhs.lldbFileSpec == rhs.lldbFileSpec
    }
}
