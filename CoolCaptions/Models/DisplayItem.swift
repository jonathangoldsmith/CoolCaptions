import Foundation

enum DisplayItem: Identifiable {
    case caption(Caption)
    case gap(Gap)

    var id: UUID {
        switch self {
            case .caption(let caption): caption.id
            case .gap(let gap): gap.id
        }
    }
}
