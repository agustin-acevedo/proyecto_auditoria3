import Foundation
import CoreData

enum BlockEditorSettingElementTypes: String {
    case color
    case gradient

    var valueKey: String {
        self.rawValue
    }
}

extension BlockEditorSettingElement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockEditorSettingElement> {
        return NSFetchRequest<BlockEditorSettingElement>(entityName: "BlockEditorSettingElement")
    }

    /// Stores the associated type that this object represents.
    /// Available types are defined in `BlockEditorSettingElementTypes`
    ///
    @NSManaged public var type: String

    /// Stores the value for the associated type. The associated field in the API response might differ based on the type.
    ///
    @NSManaged public var value: String

    /// Stores a unique key associated to the `value`.
    ///
    @NSManaged public var slug: String

    /// Stores a user friendly display name for the `slug`.
    ///
    @NSManaged public var name: String

    /// Stores maintains the order as passed from the API
    ///
    @NSManaged public var order: Int

    /// Stores a reference back to the parent `BlockEditorSettings`.
    ///
    @NSManaged public var settings: BlockEditorSettings
}

extension BlockEditorSettingElement: Identifiable {
    var rawRepresentation: [String: String]? {
        guard let type = BlockEditorSettingElementTypes(rawValue: self.type) else { return nil }
        return [
            #keyPath(BlockEditorSettingElement.slug): self.slug,
            #keyPath(BlockEditorSettingElement.name): self.name,
            type.valueKey: self.value
        ]
    }

    convenience init(fromRawRepresentation rawObject: [String: String], type: BlockEditorSettingElementTypes, order: Int, context: NSManagedObjectContext) {
        self.init(context: context)

        self.type = type.rawValue
        self.value = rawObject[type.valueKey] ?? ""
        self.slug = rawObject[#keyPath(BlockEditorSettingElement.slug)] ?? ""
        self.name = rawObject[ #keyPath(BlockEditorSettingElement.name)] ?? ""
        self.order = order
    }
}
