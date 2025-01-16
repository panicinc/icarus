import CxxLLDB

extension String {
    init?(optionalCString nullTerminatedUTF8: UnsafePointer<CChar>?) {
        guard let nullTerminatedUTF8 else {
            return nil
        }
        self = Self(cString: nullTerminatedUTF8)
    }
}