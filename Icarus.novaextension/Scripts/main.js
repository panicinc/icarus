
var langserver = null;
var taskProvider = null;

exports.activate = function() {
    langserver = new SourceKitLanguageServer();
    taskProvider = new SourceKitTaskProvider();
    
    nova.assistants.registerTaskAssistant(taskProvider, {
        'identifier': "sourcekit"
    });
}

exports.deactivate = function() {
    if (langserver) {
        langserver.deactivate();
        langserver = null;
    }
    taskProvider = null;
}

class SourceKitTaskProvider {
    resolveTaskAction(context) {
        let action = context.action;
        let data = context.data;
        let config = context.config;
        
        if (action == Task.Run && data.type == "lldbDebug") {
            let action = new TaskDebugAdapterAction("lldb");
            
            action.command = nova.path.normalize(nova.path.join(nova.extension.path, "Executables/LLDBAdapter"))
            
            // Debug Args
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
            
            return action;
        }
        else {
            return null;
        }
    }
}

class SourceKitLanguageServer {
    constructor() {
        this.languageClient = null;
        this.restartToken = null;
        this.watcher = null;
        
        nova.config.observe('sourcekit.language-server-path', (path) => {
            this.start(path);
        }, this);
        
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
        let path = nova.config.get('sourcekit.language-server-path');
        this.startWithPath(path);
    }
    
    startWithPath(path) {
        this.stop();
        
        var args = [];
        
        if (!path) {
            path = '/usr/bin/xcrun';
            args = ['sourcekit-lsp'];
        }
        
        var serverOptions = {
            path: path,
            args: args
        };
        var clientOptions = {
            syntaxes: [
                'swift',
                'c',
                'cpp',
                {'syntax': 'objc', 'languageId': 'objective-c'},
                {'syntax': 'objcpp', 'languageId': 'objective-cpp'}
            ]
        };
        var client = new LanguageClient('sourcekit-langserver', 'SourceKit Language Server', serverOptions, clientOptions);
        
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
