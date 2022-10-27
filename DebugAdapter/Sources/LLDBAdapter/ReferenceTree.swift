public struct ReferenceTree<Reference: BinaryInteger, Value> {
    public struct Entry {
        var parent: Reference?
        var key: String
        var value: Value
    }
    
    private struct ReferenceKey: Hashable {
        var reference: Reference?
        var key: String
    }
    
    private var entries: [Reference: Entry] = [:]
    private var references: [ReferenceKey: Reference] = [:]
    private var previousReferences: [ReferenceKey: Reference] = [:]
    private var nextReference: Reference = 1
    
    public init(startingAt reference: Reference = 1) {
        nextReference = reference
    }
    
    public enum ReferenceMapError: Error {
        case parentNotFound
    }
    
    public mutating func removeAll() {
        entries.removeAll()
        previousReferences = references
        references.removeAll()
    }
    
    @discardableResult
    public mutating func insert(parent: Reference?, key: String, value: Value) -> Reference {
        let newReference = previousReferences[.init(reference: parent, key: key)] ?? nextReference
        nextReference += 1
        
        entries[newReference] = .init(parent: parent, key: key, value: value)
        references[.init(reference: parent, key: key)] = newReference
        
        return newReference
    }
    
    public func entry(for reference: Reference) -> Entry? {
        return entries[reference]
    }
    
    public subscript(_ reference: Reference) -> Value? {
        return entries[reference]?.value
    }
}
