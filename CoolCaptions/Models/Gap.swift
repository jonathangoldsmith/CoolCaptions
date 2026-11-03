import Foundation

struct Gap: Identifiable {
    let id: UUID
    let start: Date
    var end: Date?

    var duration: Duration? {
        end.map { .seconds($0.timeIntervalSince(start)) }
    }
}
