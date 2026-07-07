import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var editingEntry: VisitEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    summaryHeader
                    if store.entries.isEmpty {
                        emptyState
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Routeincome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if store.canAddMore || purchases.isPurchased {
                            showAddSheet = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addEntryButton")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                EntryEditView(entry: nil) { newEntry in
                    store.add(newEntry)
                }
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditView(entry: entry) { updated in
                    store.update(updated)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .tint(Theme.accent)
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total spent")
                .font(Theme.captionFont)
                .foregroundStyle(.secondary)
            Text(store.totalSpent, format: .currency(code: "USD"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent2)
            Text("No entries yet")
                .font(Theme.headlineFont)
            Text("Tap + to log your first visit.")
                .font(Theme.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            ForEach(store.entries) { entry in
                Button {
                    editingEntry = entry
                } label: {
                    row(for: entry)
                }
                .accessibilityIdentifier("entryRow_\(entry.title)")
            }
            .onDelete { offsets in
                store.delete(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(for entry: VisitEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(Theme.bodyFont.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(entry.vendor) \u{00B7} \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.captionFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.amount, format: .currency(code: "USD"))
                .font(Theme.bodyFont.weight(.bold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 4)
    }
}

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var vendor: String
    @State private var amountText: String
    @State private var date: Date
    @State private var notes: String
    let existingId: UUID?
    let onSave: (VisitEntry) -> Void

    init(entry: VisitEntry?, onSave: @escaping (VisitEntry) -> Void) {
        _title = State(initialValue: entry?.title ?? "")
        _vendor = State(initialValue: entry?.vendor ?? "")
        _amountText = State(initialValue: entry.map { String(format: "%.2f", $0.amount) } ?? "")
        _date = State(initialValue: entry?.date ?? Date())
        _notes = State(initialValue: entry?.notes ?? "")
        existingId = entry?.id
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Visit details") {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("titleField")
                    TextField("Machine", text: $vendor)
                        .accessibilityIdentifier("vendorField")
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("amountField")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .accessibilityIdentifier("notesField")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingId == nil ? "Add Visit" : "Edit Visit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let amount = Double(amountText) ?? 0
                        let entry = VisitEntry(
                            id: existingId ?? UUID(),
                            title: title.isEmpty ? "Visit" : title,
                            vendor: vendor,
                            amount: amount,
                            date: date,
                            notes: notes
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .accessibilityIdentifier("saveEntryButton")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .accessibilityIdentifier("keyboardDoneButton")
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
