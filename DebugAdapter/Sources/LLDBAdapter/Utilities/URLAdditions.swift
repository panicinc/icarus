import Foundation

extension URL {
    /// The URL of symbolic link representing the primary (boot) volume within /Volumes
    static public let primaryVolumeURL: URL = {
        let rootURL = URL(fileURLWithPath: "/", isDirectory: true)
        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        
        var rootVolumeURL: URL?
        
        do {
            let resourceKeys: [URLResourceKey] = [.volumeURLKey]
            let contents = try FileManager.default.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: resourceKeys, options: [])
            
            for itemURL in contents {
                do {
                    let values = try itemURL.resourceValues(forKeys: Set(resourceKeys))
                    if values.isSymbolicLink == true,
                       let volumeURL = values.allValues[.volumeURLKey] as? URL, volumeURL == rootURL {
                        rootVolumeURL = itemURL
                        break
                    }
                }
                catch {
                }
            }
        }
        catch {
        }
        
        return rootVolumeURL ?? rootURL
    }()
    
    /// Whether the primary volume is case sensitive
    static let isPrimaryVolumeCaseSensitive: Bool = {
        do {
            let rootURL = URL(fileURLWithPath: "/")
            let resourceValues = try rootURL.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey])
            return resourceValues.volumeSupportsCaseSensitiveNames == true
        }
        catch {
            return false
        }
    }()
    
    /// Whether the volume containing the receiver is case sensitive
    public var isOnCaseSensitiveVolume: Bool {
        if !isFileURL {
            return false
        }
        
        do {
            let resourceValues = try resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey])
            return resourceValues.volumeSupportsCaseSensitiveNames == true
        }
        catch {
            return false
        }
    }
    
    /// Standardizes the prefix of a fileURL to not include the /Volumes/ prefix for URLs on the primary volume.
    /// This can be considerably faster than requesting a canonical path for the URL.
    public mutating func standardizeVolumeInFileURL() {
        if !isFileURL {
            return
        }
        
        let pathComponents = self.pathComponents
        let primaryVolumeName = URL.primaryVolumeURL.lastPathComponent
        
        if pathComponents.count >= 3 &&
            pathComponents[0] == "/"
            && pathComponents[1] == "Volumes"
            && pathComponents[2] == primaryVolumeName {
            // URL is on the primary volume
            
            // Build a new URL without the volumes prefix
            var newURL = URL(fileURLWithPath: "/", isDirectory: true)
            let baseIdx = 3
            for (idx, component) in pathComponents[baseIdx ..< pathComponents.count].enumerated() {
                let isDirectory = idx == ((pathComponents.count - baseIdx) - 1) ? hasDirectoryPath : true
                newURL.appendPathComponent(component, isDirectory: isDirectory)
            }
            self = newURL
        }
    }
}
