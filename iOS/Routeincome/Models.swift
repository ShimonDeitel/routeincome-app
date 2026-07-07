import Foundation

struct VisitEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var vendor: String
    var amount: Double
    var date: Date
    var notes: String = ""

    static func == (lhs: VisitEntry, rhs: VisitEntry) -> Bool {
        lhs.id == rhs.id
    }
}
