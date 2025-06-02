exports.activate = () => {
    let icarus = Icarus.shared;
    
    icarus.startLanguageServers();
    
    nova.workspace.onDidChangePath((path) => {
        icarus.startLanguageServers();
    });
    
    nova.assistants.registerTaskAssistant(icarus, {"identifier": "icarus"});
    
    nova.commands.register("icarus.restartSourceKitLSP", (workspace) => {
        return Icarus.shared.restartSourceKitLSP();
    });
    nova.commands.register("icarus.restartRustAnalyzer", (workspace) => {
        return Icarus.shared.restartRustAnalyzer();
    });
    nova.commands.register("icarus.resolveLLDBPlatforms", (workspace) => {
        return Icarus.shared.resolveLLDBPlatforms;
    });
};

exports.deactivate = () => {
    Icarus.shared.stopLanguageServers();
};

class Icarus {
    static shared = new Icarus();
    
    constructor() {
        this.sourceKitLSP = null;
        this.rustAnalyzer = null;
    }
    
    startLanguageServers() {
        this.stopLanguageServers();
        
        this.sourceKitLSP = new SourceKitLSP();
        this.rustAnalyzer = new RustAnalyzer();
    }
    
    stopLanguageServers() {
        this.sourceKitLSP?.deactivate();
        this.sourceKitLSP = null;
        
        this.rustAnalyzer?.deactivate();
        this.rustAnalyzer = null;
    }
    
    restartSourceKitLSP() {
        this.sourceKitLSP?.start();
    }
    
    restartRustAnalyzer() {
        this.rustAnalyzer?.start();
    }
    
    static debugAdapterPath() {
        let adapterPath = nova.path.normalize(nova.path.join(nova.extension.path, "Executables/LLDBAdapter"));
        
        // Check adapter executability.
        if (!nova.fs.access(adapterPath, nova.fs.F_OK + nova.fs.X_OK)) {
            // Set +x on the adapter to get around an issue with extensions being installed by Nova.
            nova.fs.chmod(adapterPath, 0o755);
        }
        
        return adapterPath;
    }
    
    static lldbFrameworkPaths() {
        let toolchain = nova.config.get("icarus.toolchain");
        let toolchainPath = nova.config.get("icarus.toolchain-path");
        
        // Set DYLD framework paths for finding LLDB.framework.
        let frameworkPaths = [];
        
        if (toolchain == "swift") {
            // Swift "latest" toolchain
            frameworkPaths.push("/Library/Developer/Toolchains/swift-latest.xctoolchain/System/Library/PrivateFrameworks/");
        }
        else if (toolchain == "custom" && toolchainPath) {
            // Custom toolchain
            frameworkPaths.push(nova.path.join(toolchainPath, "System/Library/PrivateFrameworks/"));
        }
        
        // Fallback to Xcode and CLI tools
        frameworkPaths.push("/Applications/Xcode-beta.app/Contents/SharedFrameworks/");
        frameworkPaths.push("/Applications/Xcode.app/Contents/SharedFrameworks/");
        frameworkPaths.push("/Library/Developer/CommandLineTools/Library/PrivateFrameworks/");
        
        return frameworkPaths;
    }
    
    resolveLLDBPlatforms() {
        return new Promise((resolve, reject) => {
            let adapterPath = Icarus.debugAdapterPath();
            
            let env = {};
            
            let frameworkPaths = Icarus.lldbFrameworkPaths();
            env.DYLD_FRAMEWORK_PATH = frameworkPaths.join(":");
            
            let process = new Process(adapterPath, {
                args: ["platforms"],
                env: env,
            });
            
            var platforms = [];
            
            process.onStdout((line) => {
                let components = line.trim().split(": ", 2);
                if (components.length < 2) {
                    return;
                }
                let identifier = components[0];
                if (identifier == "host") {
                    return;
                }
                let description = components[1];
                platforms.push([identifier, `${identifier}: ${description}`]);
            });
            
            process.onDidExit(() => {
                resolve(platforms);
            });
            
            try {
                process.start();
            }
            catch (err) {
                reject(err);
            }
        });
    }
    
    resolveTaskAction(context) {
        let action = context.action;
        let data = context.data;
        let config = context.config;
        
        if (action == Task.Run) {
            let action = new TaskDebugAdapterAction("lldb");
            
            action.command = Icarus.debugAdapterPath();
            
            // Environment
            let env = {};
            
            // Set DYLD framework paths for finding LLDB.framework.
            let frameworkPaths = Icarus.lldbFrameworkPaths();
            env.DYLD_FRAMEWORK_PATH = frameworkPaths.join(":");
            
            action.env = env;
            
            // Debug Args
            if (data.type == "lldbDebug") {
                // LLDB Debug
                let request = config.get("request", "string");
                if (!request) {
                    request = "launch";
                }
                action.debugRequest = request;
                
                let debugArgs = {};
                
                debugArgs.program = config.get("launchPath", "string");
                debugArgs.args = config.get("launchArgs", "array");
                debugArgs.cwd = config.get("cwd", "string");
                debugArgs.runInRosetta = config.get("runInRosetta", "boolean");
                debugArgs.stopOnEntry = config.get("stopAtEntry", "boolean");
                if (request == "attach") {
                    debugArgs.waitFor = true;
                }
                
                action.debugArgs = debugArgs;
            }
            else  if (data.type == "lldbRemoteDebug") {
                // LLDB Remote Debug
                let request = config.get("request", "string");
                if (!request) {
                    request = "launch";
                }
                action.debugRequest = request;
                
                let debugArgs = {};
                
                debugArgs.host = config.get("host", "string");
                debugArgs.port = config.get("port", "integer");
                debugArgs.platform = config.get("platform", "string");
                debugArgs.program = config.get("launchPath", "string");
                debugArgs.args = config.get("launchArgs", "array");
                debugArgs.cwd = config.get("cwd", "string");
                debugArgs.stopOnEntry = config.get("stopAtEntry", "boolean");
                if (request == "attach") {
                    debugArgs.waitFor = true;
                }
                
                let pathMappings = config.get("pathMappings");
                if (pathMappings) {
                    // Ensure the local half of mappings are absolute paths.
                    let basePath = nova.workspace.path;
                    debugArgs.pathMappings = pathMappings.map(mapping => {
                        let local = mapping.localRoot;
                        let remote = mapping.remoteRoot;
                        if (!nova.path.isAbsolute(local)) {
                            local = nova.path.normalize(nova.path.join(basePath, local));
                        }
                        return {"local": local, "remote": remote};
                    });
                }
                
                action.debugArgs = debugArgs;
            }
            
            return action;
        }
        else {
            return null;
        }
    }
    
    static subpathExists(path) {
        let workspacePath = nova.workspace.path;
        if (!workspacePath) {
            return false;
        }
        return nova.fs.access(nova.path.join(nova.workspace.path, path), nova.fs.F_OK);
    }
}

class LanguageServer {
    constructor(id, name) {
        this.id = id
        this.name = name;
        this.languageClient = null;
        this.restartToken = null;
        this.watchers = [];
        
        this.start();
    }
    
    deactivate() {
        this.stop();
        
        if (this.restartToken) {
            clearTimeout(this.restartToken);
        }
        
        for (let watcher of this.watchers) {
            watcher.dispose();
        }
        this.watchers = [];
    }
    
    makeLanguageClient() {
        console.error("makeLanguageClient() must be implemented by subclasses");
        return null;
    }
    
    shouldStart() {
        return true;
    }
    
    start() {
        this.stop();
        
        if (!this.shouldStart()) {
            return;
        }
        
        let client = this.makeLanguageClient();
        if (!client) {
            return;
        }
        
        client.onDidStop((error) => {
            if (error) {
                this.showStopError(error);
            }
        });
        
        try {
            client.start();
            this.languageClient = client;
        }
        catch (error) {
            this.showStartError(error);
        }
    }
    
    stop() {
        this.languageClient?.stop();
        this.languageClient = null;
    }
    
    watch(pattern) {
        if (!nova.workspace.path) {
            return;
        }
        
        this.watchers.push(nova.fs.watch(pattern, (path) => {
            this.fileChanged(path);
        }));
    }
    
    fileChanged(path) {
    }
    
    scheduleRestart() {
        let token = this.restartToken;
        if (token != null) {
            clearTimeout(token);
        }
        
        let server = this;
        this.restartToken = setTimeout(() => {
            server.start();
        }, 1000);
    }
    
    showStartError(error) {
        let notif = new NotificationRequest(`panic.icarus.${this.id}.start-failed`);
        notif.title = `${this.name} Failed To Start`;
        notif.body = `The language server encountered an error:\n\n${error}`;
        nova.notifications.add(notif);
    }
    
    showStopError(error) {
        let notif = new NotificationRequest(`panic.icarus.${this.id}.quit-unexpectedly`);
        notif.title = `${this.name} Quit Unexpectedly`;
        notif.body = `The language server encountered an error:\n\n${error}`;
        notif.actions = ["Restart", "Ignore"];
        
        (async () => {
            let reply = await nova.notifications.add(notif);
            if (reply.actionIdx == 0) {
                this.start();
            }
        })();
    }
}

class SourceKitLSP extends LanguageServer {
    constructor() {
        super("sourcekit-lsp", "SourceKit-LSP");
        
        nova.config.onDidChange("icarus.language-server-path", (path) => {
            this.start();
        });
        nova.config.onDidChange("icarus.toolchain", (path) => {
            this.start();
        });
        nova.config.onDidChange("icarus.toolchain-path", (path) => {
            this.start();
        });
        
        nova.workspace.onDidChangePath((path) => {
            this.startWatcher();
        });
        
        this.watch("/*.*");
    }
    
    fileChanged(path) {
        let name = nova.path.basename(path);
        if (name == "compile_commands.json" || name == "compile_flags.txt") {
            this.scheduleRestart();
        }
    }
    
    makeLanguageClient() {
        let toolchain = nova.config.get("icarus.toolchain");
        let toolchainPath = nova.config.get("icarus.toolchain-path");
        
        let path = nova.config.get("icarus.language-server-path");
        let warnIfMissing = false;
        let args = [];
        let env = {};
        
        if (!path) {
            if (toolchain == "xcrun" || !toolchain) {
                path = "/usr/bin/xcrun";
                args.push("sourcekit-lsp");
            }
            else if (toolchain == "swift") {
                path = "/usr/bin/xcrun";
                args.push("--toolchain");
                args.push("swift");
                args.push("sourcekit-lsp");
            }
            else if (toolchain == "swiftly") {
                path = "/bin/bash";
                args.push("-c");
                args.push("swiftly run sourcekit-lsp");
            }
            else if (toolchain == "custom") {
                if (toolchainPath) {
                    path = nova.path.join(toolchainPath, "usr/bin/sourcekit-lsp");
                    warnIfMissing = true;
                }
            }
        }
        
        if (toolchainPath) {
            env.SOURCEKIT_TOOLCHAIN_PATH = toolchainPath;
        }
        
        if (!path) {
            console.log(`sourcekit-lsp not found within the chosen Swift toolchain; skipping`);
            return null;
        }
        else if (!nova.fs.access(path, nova.fs.F_OK + nova.fs.X_OK)) {
            console.log(`sourcekit-lsp not found: ${path} ${args.join(" ")}`);
            return null;
        }
        
        console.log(`Starting sourcekit-lsp: ${path} ${args.join(" ")}`);
        
        return new LanguageClient(
            this.id,
            this.name,
            {
                path: path,
                args: args,
                env: env
            },
            {
                syntaxes: [
                    "c",
                    "cpp",
                    {"syntax": "objc", "languageId": "objective-c"},
                    {"syntax": "objcpp", "languageId": "objective-cpp"},
                    "swift"
                ]
            }
        );
    }
}

class RustAnalyzer extends LanguageServer {
    constructor() {
        super("rust-analyzer", "rust-analyzer");
        
        nova.config.onDidChange("icarus.rust-analyzer-path", (path) => {
            this.start();
        });
        
        this.watch("/*.*");
    }
    
    shouldStart() {
        return Icarus.subpathExists("Cargo.toml") || Icarus.subpathExists("rust-project.json");
    }
    
    fileChanged(path) {
        let name = nova.path.basename(path);
        if (name == "Cargo.toml" || name == "rust-project.json" || name == ".rust-analyzer.json") {
            this.scheduleRestart();
        }
    }
    
    makeLanguageClient() {
        let path = nova.config.get("icarus.rust-analyzer-path");
        let args = [];
        let env = {};
        
        if (!path) {
            let defaultPaths = [
                "/usr/local/bin/rust-analyzer",
                "/opt/homebrew/bin/rust-analyzer"
            ];
            
            for (let defaultPath of defaultPaths) {
                if (nova.fs.access(defaultPath, nova.fs.X_OK)) {
                    path = defaultPath;
                    break;
                }
            }
        }
        
        if (!path) {
            console.log(`rust-analyzer not found in any default location; skipping`);
            return null;
        }
        else if (!nova.fs.access(path, nova.fs.X_OK)) {
            console.log(`rust-analyzer not found: ${path} ${args.join(" ")}`);
            return null;
        }
        
        let initOptions = {};
        
        let configPath = nova.path.join(nova.workspace.path, ".rust-analyzer.json");
        if (nova.fs.access(configPath, nova.fs.R_OK)) {
            console.log(`Reading rust-analyzer config from .rust-analyzer.json`);
            let configFile = nova.fs.open(configPath);
            let string = configFile.read();
            if (string) {
                try {
                    initOptions = JSON.parse(string);
                    console.log(string);
                }
                catch (err) {
                    console.error(`Error reading config: ${err}`);
                }
            }
            configFile.close();
        }
        
        console.log(`Starting rust-analyze: ${path} ${args.join(" ")}`);
        
        return new LanguageClient(
            "rust-analyzer",
            this.name,
            {
                path: path,
                args: args,
                env: env
            },
            {
                syntaxes: ["rust"],
                initializationOptions: initOptions
            }
        );
    }
}
