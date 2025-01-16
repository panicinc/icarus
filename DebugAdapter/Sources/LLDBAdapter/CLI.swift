import ArgumentParser
import SwiftLLDB

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
        try Debugger.initialize()
        
        let debugger = Debugger()
        for platform in debugger.availablePlatforms {
            print("\(platform.name): \(platform.caption ?? "")")
        }
        
        Debugger.terminate()
    }
}
