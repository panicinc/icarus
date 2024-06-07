import CxxLLDB

public struct LLDBError: Error {
    private let error: lldb.SBError
    
    init(_ error: lldb.SBError) {
        self.error = error
    }
}

extension lldb.SBError {
    func throwOnFail() throws {
        if Fail() {
            throw LLDBError(self)
        }
    }
}
