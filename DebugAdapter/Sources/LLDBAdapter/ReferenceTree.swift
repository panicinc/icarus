struct ReferenceTree<Reference: BinaryInteger, Value> {
    private struct Entry {
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
    
    init(startingAt reference: Reference = 1) {
        nextReference = reference
    }
    
    mutating func removeAll() {
        entries.removeAll()
        previousReferences = references
        references.removeAll()
    }
    
    @discardableResult
    mutating func insert(parent: Reference?, key: String, value: Value) -> Reference {
        let newReference = previousReferences[.init(reference: parent, key: key)] ?? nextReference
        nextReference += 1
        
        entries[newReference] = .init(parent: parent, key: key, value: value)
        references[.init(reference: parent, key: key)] = newReference
        
        return newReference
    }
    
    subscript(_ reference: Reference) -> Value? {
        return entries[reference]?.value
    }
}
