import ArgumentParser
import LLDBObjC

@main
struct DebugAdapterCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "DebugAdapter", subcommands: [
        RunCommand.self,
        PlatformsCommand.self,
    ], defaultSubcommand: RunCommand.self)
}

struct RunCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "run")
    
    func run() throws {
        Adapter.shared.resume()
    }
}

struct PlatformsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "platforms")
    
    func run() throws {
        try LLDBDebugger.initializeWithError()
        
        let debugger = LLDBDebugger()
        for platform in debugger.availablePlatforms {
            print("\(platform.name ?? "unknown"): \(platform.descriptiveText ?? "")")
        }
        
        LLDBDebugger.terminate()
    }
}
