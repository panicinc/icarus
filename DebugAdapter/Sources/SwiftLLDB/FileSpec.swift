import CxxLLDB

public struct FileSpec: Equatable {
    let lldbFileSpec: lldb.SBFileSpec
    
    init(_ lldbFileSpec: lldb.SBFileSpec) {
        self.lldbFileSpec = lldbFileSpec
    }
    
    public static func == (lhs: FileSpec, rhs: FileSpec) -> Bool {
        return lhs.lldbFileSpec == rhs.lldbFileSpec
    }
    
    public var directory: String? {
        if let directory = lldbFileSpec.GetDirectory() {
            return String(cString: directory)
        }
        else {
            return nil
        }
    }
    
    public var filename: String? {
        if let filename = lldbFileSpec.GetFilename() {
            return String(cString: filename)
        }
        else {
            return nil
        }
    }
    
    public var path: String? {
        guard let directory,
              let filename else {
            return nil
        }
        return "\(directory)/\(filename)"
    }
}
