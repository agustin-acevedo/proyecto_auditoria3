import Foundation

enum DashboardCardModel: Hashable {

    case `default`(DashboardCardDefaultModel)
    case dynamic(DashboardDynamicCardModel)

    var cardType: DashboardCard {
        switch self {
        case .default(let model): return model.cardType
        case .dynamic: return .dynamic
        }
    }

    func `default`() -> DashboardCardDefaultModel? {
        guard case .default(let model) = self else {
            return nil
        }
        return model
    }

    func dynamic() -> DashboardDynamicCardModel? {
        guard case .dynamic(let model) = self else {
            return nil
        }
        return model
    }
}

/// Represents a card in the dashboard collection view
struct DashboardCardDefaultModel: Hashable {
    let cardType: DashboardCard
    let dotComID: Int
    let apiResponse: BlogDashboardRemoteEntity?

    /**
     Initializes a new DashboardCardModel, used as a model for each dashboard card.

     - Parameters:
     - id: The `DashboardCard` id of this card
     - dotComID: The blog id for the blog associated with this card
     - entity: A `BlogDashboardRemoteEntity?` property

     - Returns: A `DashboardCardModel` that is used by the dashboard diffable collection
                view. The `id`, `dotComID` and the `entity` is used to differentiate one
                card from the other.
    */
    init(cardType: DashboardCard, dotComID: Int, entity: BlogDashboardRemoteEntity? = nil) {
        self.cardType = cardType
        self.dotComID = dotComID
        self.apiResponse = entity
    }

    static func == (lhs: DashboardCardDefaultModel, rhs: DashboardCardDefaultModel) -> Bool {
        lhs.cardType == rhs.cardType &&
        lhs.dotComID == rhs.dotComID &&
        lhs.apiResponse == rhs.apiResponse
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(dotComID)
        hasher.combine(apiResponse)
    }
}

struct DashboardDynamicCardModel: Hashable {

    typealias Payload = BlogDashboardRemoteEntity.BlogDashboardDynamic

    let payload: Payload
    let dotComID: Int
}
