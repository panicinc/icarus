
var langserver = null;
var taskProvider = null;

exports.activate = function() {
    langserver = new SourceKitLanguageServer();
    taskProvider = new SourceKitTaskProvider();
    
    nova.assistants.registerTaskAssistant(taskProvider, {
        'identifier': "sourcekit"
    })
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
        nova.config.observe('sourcekit.language-server-path', function(path) {
            this.start(path);
        }, this);
    }
    
    deactivate() {
        this.stop();
    }
    
    start() {
        let path = nova.config.get('sourcekit.language-server-path');
        this.start(path);
    }
    
    start(path) {
        if (this.languageClient) {
            this.languageClient.stop();
            nova.subscriptions.remove(this.languageClient);
        }
        
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
        if (this.languageClient) {
            this.languageClient.stop();
            nova.subscriptions.remove(this.languageClient);
            this.languageClient = null;
        }
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
