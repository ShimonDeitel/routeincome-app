import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published private(set) var entries: [VisitEntry] = []
    @Published var isProUnlocked: Bool = false

    /// Free tier allows this many entries before the paywall is shown.
    /// Always kept above the seed data count so a fresh install never
    /// hits the paywall immediately.
    static let freeLimit = 8

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Routeincome", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("entries.json")
        load()
    }

    var canAddMore: Bool {
        isProUnlocked || entries.count < Store.freeLimit
    }

    var totalSpent: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    func add(_ entry: VisitEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func update(_ entry: VisitEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func delete(_ entry: VisitEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([VisitEntry].self, from: data) {
            entries = decoded
        } else {
            entries = Self.seedData()
            save()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func seedData() -> [VisitEntry] {
        let cal = Calendar.current
        let now = Date()
        return [
            VisitEntry(title: "First visit", vendor: "Machine A", amount: 24.00, date: cal.date(byAdding: .day, value: -30, to: now) ?? now, notes: ""),
            VisitEntry(title: "Regular visit", vendor: "Machine B", amount: 32.50, date: cal.date(byAdding: .day, value: -14, to: now) ?? now, notes: ""),
            VisitEntry(title: "Recent visit", vendor: "Machine A", amount: 18.75, date: cal.date(byAdding: .day, value: -3, to: now) ?? now, notes: ""),
        ]
    }
}
