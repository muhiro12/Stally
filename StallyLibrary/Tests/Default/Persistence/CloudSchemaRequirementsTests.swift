import CoreData
import SwiftData
import Testing

@testable import StallyLibrary

struct CloudSchemaRequirementsTests {
    @Test
    func generatedSchemaHasCloudCompatibleDefaultsAndRelationships() throws {
        let model = try #require(NSManagedObjectModel.makeManagedObjectModel(for: StallySchema.models))
        for entity in model.entities {
            for attribute in entity.attributesByName.values {
                #expect(
                    attribute.isOptional || attribute.defaultValue != nil,
                    "Missing default: \(entity.name ?? "").\(attribute.name)"
                )
            }
            for relationship in entity.relationshipsByName.values {
                #expect(relationship.isOptional)
                #expect(relationship.inverseRelationship != nil)
                #expect(relationship.deleteRule != .denyDeleteRule)
            }
            #expect(entity.uniquenessConstraints.isEmpty)
        }
    }
}
