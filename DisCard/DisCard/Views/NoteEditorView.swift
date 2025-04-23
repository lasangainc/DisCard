import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var noteStore: NoteStore
    
    let note: Note?
    let isEditing: Bool
    @State private var title: String
    @State private var content: String
    @State private var selectedExpiryOption: ExpiryOption
    
    enum ExpiryOption: String, CaseIterable, Identifiable {
        case thirtySeconds = "30 seconds"
        case thirtyMinutes = "30 minutes"
        case hour = "1 hour"
        case day = "1 day"
        case week = "1 week"
        case month = "1 month"
        case sixMonths = "6 months"
        case year = "1 year"
        
        var id: String { rawValue }
        
        var timeInterval: TimeInterval {
            switch self {
            case .thirtySeconds:
                return 30
            case .thirtyMinutes:
                return 30 * 60
            case .hour:
                return 60 * 60
            case .day:
                return 24 * 60 * 60
            case .week:
                return 7 * 24 * 60 * 60
            case .month:
                return 30 * 24 * 60 * 60
            case .sixMonths:
                return 180 * 24 * 60 * 60
            case .year:
                return 365 * 24 * 60 * 60
            }
        }
    }
    
    init(note: Note? = nil, isEditing: Bool = false) {
        self.note = note
        self.isEditing = isEditing
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        
        if let note = note {
            let timeInterval = note.expiryDate.timeIntervalSince(Date())
            if timeInterval <= ExpiryOption.thirtyMinutes.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .thirtyMinutes)
            } else if timeInterval <= ExpiryOption.hour.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .hour)
            } else if timeInterval <= ExpiryOption.day.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .day)
            } else if timeInterval <= ExpiryOption.week.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .week)
            } else if timeInterval <= ExpiryOption.month.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .month)
            } else if timeInterval <= ExpiryOption.sixMonths.timeInterval * 1.5 {
                _selectedExpiryOption = State(initialValue: .sixMonths)
            } else {
                _selectedExpiryOption = State(initialValue: .year)
            }
        } else {
            _selectedExpiryOption = State(initialValue: .hour)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                    .font(.headline)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                TextField("Content", text: $content, axis: .vertical)
                    .font(.body)
                    .lineLimit(5...)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .frame(height: 100)
                
                HStack {
                    Text("Expires in")
                    Spacer()
                    Picker("", selection: $selectedExpiryOption) {
                        ForEach(ExpiryOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
            .padding()
            .frame(width: 400, height: 320)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let expiryDate = Date().addingTimeInterval(selectedExpiryOption.timeInterval)
        
        let newNote = Note(
            id: note?.id ?? UUID(),
            title: title,
            content: content,
            expiryDate: expiryDate
        )
        
        if note != nil {
            noteStore.updateNote(newNote)
        } else {
            noteStore.addNote(newNote)
        }
    }
} 