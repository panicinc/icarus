
var langserver = null;
var taskProvider = null;

exports.activate = function() {
    langserver = new IcarusLanguageServer();
    taskProvider = new IcarusTaskProvider();
    
    nova.assistants.registerTaskAssistant(taskProvider, {
        'identifier': "icarus"
    });
}

exports.deactivate = function() {
    if (langserver) {
        langserver.deactivate();
        langserver = null;
    }
    taskProvider = null;
}

class IcarusTaskProvider {
    resolveTaskAction(context) {
        let action = context.action;
        let data = context.data;
        let config = context.config;
        
        if (action == Task.Run) {
            let toolchain = nova.config.get('icarus.toolchain');
            let toolchainPath = nova.config.get('icarus.toolchain-path');
            
            let action = new TaskDebugAdapterAction("lldb");
            
            let adapterPath = nova.path.normalize(nova.path.join(nova.extension.path, "Executables/LLDBAdapter"));
            
            // Check adapter executability.
            if (!nova.fs.access(adapterPath, nova.fs.constants.X_OK)) {
                // Set +x on the adapter to get around an issue with extensions being installed by Nova.
                nova.fs.chmod(adapterPath, 0o755);
            }
            
            action.command = adapterPath;
            
            // Environment
            let env = {};
            
            // Set DYLD framework paths for finding LLDB.framework.
            let frameworkPaths = [];
            
            if (toolchain == 'swift') {
                // Swift "latest" toolchain
                frameworkPaths.push("/Library/Developer/Toolchains/swift-latest.xctoolchain/System/Library/PrivateFrameworks/");
            }
            else if (toolchain == 'custom' && toolchainPath) {
                // Custom toolchain
                frameworkPaths.push(nova.path.join(toolchainPath, 'System/Library/PrivateFrameworks/'));
            }
            
            // Fallback to Xcode and CLI tools
            frameworkPaths.push("/Applications/Xcode-beta.app/Contents/SharedFrameworks/");
            frameworkPaths.push("/Applications/Xcode.app/Contents/SharedFrameworks/");
            frameworkPaths.push("/Library/Developer/CommandLineTools/Library/PrivateFrameworks/");
            
            env['DYLD_FRAMEWORK_PATH'] = frameworkPaths.join(":");
            
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
                debugArgs.runInRosetta = config.get("runInRosetta", "boolean");
                debugArgs.stopAtEntry = config.get("stopAtEntry", "boolean");
                debugArgs.wait = request == "attach";
                
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
                debugArgs.program = config.get("launchPath", "string");
                debugArgs.args = config.get("launchArgs", "array");
                debugArgs.stopAtEntry = config.get("stopAtEntry", "boolean");
                debugArgs.wait = request == "attach";
                
                let pathMappings = config.get("pathMappings");
                if (pathMappings) {
                    // Ensure the local part of path mappings are absolute
                    let basePath = nova.workspace.path;
                    debugArgs.pathMappings = pathMappings.map(mapping => {
                        let local = mapping.localRoot;
                        let remote = mapping.remoteRoot;
                        if (!nova.path.isAbsolute(local)) {
                            local = nova.path.normalize(nova.path.join(basePath, local));
                        }
                        return {"localRoot": local, "remoteRoot": remote};
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
}

class IcarusLanguageServer {
    constructor() {
        this.languageClient = null;
        this.restartToken = null;
        this.watcher = null;
        
        nova.config.onDidChange('icarus.language-server-path', (path) => {
            this.start();
        }, this);
        nova.config.onDidChange('icarus.toolchain', (path) => {
            this.start();
        }, this);
        nova.config.onDidChange('icarus.toolchain-path', (path) => {
            this.start();
        }, this);
        
        this.start();
        
        nova.workspace.onDidChangePath((path) => {
            this.startWatcher();
        }, this);
        
        let langserver = this;
        this.startWatcher();
    }
    
    deactivate() {
        this.stop();
        
        if (this.watcher) {
            this.watcher.dispose()
            this.watcher = null;
        }
        
        if (this.restartToken) {
            clearTimeout(this.restartToken);
        }
    }
    
    startWatcher() {
        if (this.watcher) {
            this.watcher.dispose()
            this.watcher = null;
        }
        
        let workspacePath = nova.workspace.path;
        if (workspacePath) {
            this.watcher = nova.fs.watch("compile_commands.json", (path) => {
                langserver.fileDidChange(path);
            });
        }
    }
    
    start() {
        this.stop();
        
        let toolchain = nova.config.get('icarus.toolchain');
        let toolchainPath = nova.config.get('icarus.toolchain-path');
        
        let path = nova.config.get('icarus.language-server-path');
        let args = [];
        let env = {};
        
        if (!path) {
            if (toolchain == 'swift') {
                path = '/usr/bin/xcrun';
                args.push('--toolchain');
                args.push('swift');
                args.push('sourcekit-lsp');
            }
            else if (toolchain == 'custom' && toolchainPath) {
                path = nova.path.join(toolchainPath, 'usr/bin/sourcekit-lsp');
            }
            else {
                path = '/usr/bin/xcrun';
                args.push('sourcekit-lsp');
            }
        }
        
        if (toolchainPath) {
            env['SOURCEKIT_TOOLCHAIN_PATH'] = toolchainPath;
        }
        
        console.log("Starting sourcekit-lsp " + path + " " + args.join(" "));
        
        let serverOptions = {
            path: path,
            args: args,
            env: env
        };
        let clientOptions = {
            // debug: true,
            syntaxes: [
                'swift',
                'c',
                'cpp',
                {'syntax': 'objc', 'languageId': 'objective-c'},
                {'syntax': 'objcpp', 'languageId': 'objective-cpp'}
            ]
        };
        let client = new LanguageClient('sourcekit-lsp', 'SourceKit-LSP', serverOptions, clientOptions);
        
        client.onDidStop((error) => {
            if (error) {
                this.showStoppedUnexpectedlyNotification(error);
            }
        }, this);
        
        try {
            client.start();
            
            nova.subscriptions.add(client);
            this.languageClient = client;
        }
        catch (err) {
            console.error(err);
        }
    }
    
    stop() {
        let langclient = this.languageClient;
        this.languageClient = null;
        
        if (langclient) {
            langclient.stop();
            nova.subscriptions.remove(langclient);
        }
    }
    
    fileDidChange(path) {
        let lastPathComponent = nova.path.basename(path);
        if (lastPathComponent == "compile_commands.json" || lastPathComponent == "compile_flags.txt") {
            // Restart sourcekit-lsp
            this.scheduleRestart()
        }
    }
    
    scheduleRestart() {
        let token = this.restartToken;
        if (token != null) {
            clearTimeout(token);
        }
        
        let langserver = this;
        this.restartToken = setTimeout(() => {
            langserver.start();
        }, 1000);
    }
    
    showStoppedUnexpectedlyNotification(error) {
        let request = new NotificationRequest("panic.sourcekit-langserver.quit-unexpectedly");
        request.title = "SourceKit-LSP Quit Unexpectedly";
        request.body = `The language server encountered an error: ${error}`;
        request.actions = ["Restart", "Ignore"];
        
        let langserver = this;
        
        let promise = nova.notifications.add(request);
        promise.then(reply => {
            if (reply.actionIdx == 0) {
                // Restart server
                langserver.start();
            }
        });
    }
}
