import CxxLLDB

public struct Platform {
    let lldbPlatform: lldb.SBPlatform
    
    init(_ lldbPlatform: lldb.SBPlatform) {
        self.lldbPlatform = lldbPlatform
    }
    
    public init(name: String) {
        self.lldbPlatform = lldb.SBPlatform(name)
    }
    
    public var name: String? {
        var lldbPlatform = lldbPlatform
        if let str = lldbPlatform.GetName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var triple: String? {
        var lldbPlatform = lldbPlatform
        if let str = lldbPlatform.GetTriple() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var hostname: String? {
        var lldbPlatform = lldbPlatform
        if let str = lldbPlatform.GetHostname() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public struct ConnectOptions {
        public var url: String
        public var isRsyncEnabled = false
        public var rsyncOptions: String?
        public var rsyncRemotePathPrefix: String?
        public var rsyncOmitRemoteHostname = false
        
        public init(url: String) {
            self.url = url
        }
    }
    
    public var isConnected: Bool {
        var lldbPlatform = lldbPlatform
        return lldbPlatform.IsConnected()
    }
    
    public func connect(with options: ConnectOptions) throws {
        var lldbOptions = lldb.SBPlatformConnectOptions(options.url)
        
        if options.isRsyncEnabled {
            lldbOptions.EnableRsync(options.rsyncOptions, options.rsyncRemotePathPrefix, options.rsyncOmitRemoteHostname)
        }
        
        var lldbPlatform = lldbPlatform
        let error = lldbPlatform.ConnectRemote(&lldbOptions)
        try error.throwOnFail()
    }
    
    public func disconnect() {
        var lldbPlatform = lldbPlatform
        lldbPlatform.DisconnectRemote()
    }
}
