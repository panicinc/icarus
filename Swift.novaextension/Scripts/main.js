
var langserver = null;

exports.activate = function() {
    langserver = new SourceKitLanguageServer();
}

exports.deactivate = function() {
    if (langserver) {
        langserver.deactivate();
        langserver = null;
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
}
