import CxxLLDB

public struct Platform: Sendable {
    let lldbPlatform: lldb.SBPlatform
    
    init?(_ lldbPlatform: lldb.SBPlatform) {
        guard lldbPlatform.IsValid() else {
            return nil
        }
        self.lldbPlatform = lldbPlatform
    }
    
    public init?(named: String) {
        self.init(lldb.SBPlatform(named))
    }
}

extension Platform {
    public var name: String? {
        var lldbPlatform = lldbPlatform
        return String(optionalCString: lldbPlatform.GetName())
    }
    
    public var triple: String? {
        var lldbPlatform = lldbPlatform
        return String(optionalCString: lldbPlatform.GetTriple())
    }
    
    public var hostname: String? {
        var lldbPlatform = lldbPlatform
        return String(optionalCString: lldbPlatform.GetHostname())
    }
}

extension Platform {
    public struct ConnectOptions: Sendable {
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
    
    public func connect(_ options: ConnectOptions) throws {
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
