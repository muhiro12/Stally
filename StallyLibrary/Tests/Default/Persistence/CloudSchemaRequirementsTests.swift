import CoreData
import SwiftData
import Testing

@testable import StallyLibrary

struct CloudSchemaRequirementsTests {
    @Test
    func optionalTextHasNoEmptyStringSchemaDefault() throws {
        let model = try #require(NSManagedObjectModel.makeManagedObjectModel(for: StallySchema.models))
        let fields = ["Item": ["note", "representativeURL"], "ItemPhoto": ["caption"],
                      "ItemPeriod": ["startLocalDate", "endLocalDate"]]
        for (name, properties) in fields {
            let entity = try #require(model.entities.first { $0.name == name })
            for property in properties {
                let attribute = try #require(entity.attributesByName[property])
                #expect(attribute.isOptional && attribute.defaultValue == nil)
            }
        }
    }

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
