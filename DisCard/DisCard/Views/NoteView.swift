import SwiftUI

struct NoteView: View {
    let note: Note
    @EnvironmentObject private var noteStore: NoteStore
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var title: String
    @State private var content: String
    @State private var selectedExpiryOption: NoteEditorView.ExpiryOption
    @State private var isDeleting = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var countdownTimer: Timer?
    
    init(note: Note) {
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        
        let timeInterval = note.expiryDate.timeIntervalSince(Date())
        let option: NoteEditorView.ExpiryOption
        
        if timeInterval <= NoteEditorView.ExpiryOption.thirtySeconds.timeInterval * 1.5 {
            option = .thirtySeconds
        } else if timeInterval <= NoteEditorView.ExpiryOption.thirtyMinutes.timeInterval * 1.5 {
            option = .thirtyMinutes
        } else if timeInterval <= NoteEditorView.ExpiryOption.day.timeInterval * 1.5 {
            option = .day
        } else if timeInterval <= NoteEditorView.ExpiryOption.week.timeInterval * 1.5 {
            option = .week
        } else if timeInterval <= NoteEditorView.ExpiryOption.month.timeInterval * 1.5 {
            option = .month
        } else if timeInterval <= NoteEditorView.ExpiryOption.sixMonths.timeInterval * 1.5 {
            option = .sixMonths
        } else {
            option = .year
        }
        
        _selectedExpiryOption = State(initialValue: option)
        _timeRemaining = State(initialValue: timeInterval)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $title)
                        .font(.headline)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 2)
                    
                    ScrollView {
                        TextField("Content", text: $content, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(3...)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 2)
                    }
                    .frame(height: 50)
                    
                    Spacer()
                    
                    HStack {
                        Text("Expires in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedExpiryOption) {
                            ForEach(NoteEditorView.ExpiryOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                }
            } else {
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                    Spacer()
                    if isHovered {
                        Button {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                isDeleting = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                noteStore.deleteNote(note)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                ScrollView {
                    Text(note.content)
                        .font(.subheadline)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 50)
                
                Spacer()
                
                Text("Expires in \(timeUntilExpiry)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 2)
            }
        }
        .padding(8)
        .frame(width: 160, height: 140)
        .background(Color(nsColor: .systemYellow))
        .cornerRadius(8)
        .shadow(radius: 2, x: 0, y: 1)
        .scaleEffect(isDeleting ? 0.5 : 1.0)
        .opacity(isDeleting ? 0 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if !isEditing {
                isEditing = true
            }
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private func saveChanges() {
        let expiryDate = Date().addingTimeInterval(selectedExpiryOption.timeInterval)
        
        let updatedNote = Note(
            id: note.id,
            title: title,
            content: content,
            expiryDate: expiryDate
        )
        
        noteStore.updateNote(updatedNote)
    }
    
    private func startCountdown() {
        countdownTimer?.invalidate()
        timeRemaining = note.expiryDate.timeIntervalSince(Date())
        
        if timeRemaining <= 60 { // Only start countdown if less than a minute remaining
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                timeRemaining = note.expiryDate.timeIntervalSince(Date())
                if timeRemaining <= 0 {
                    countdownTimer?.invalidate()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isDeleting = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        noteStore.deleteNote(note)
                    }
                }
            }
        }
    }
    
    private var timeUntilExpiry: String {
        if timeRemaining <= 0 {
            return "now"
        } else if timeRemaining <= 60 {
            return String(format: "%.0f seconds", timeRemaining)
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: note.expiryDate)
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if days < 1 {
            if hours < 1 {
                if minutes <= 0 {
                    return "now"
                } else if minutes == 1 {
                    return "1 minute"
                } else {
                    return "\(minutes) minutes"
                }
            } else if hours == 1 {
                return "1 hour"
            } else {
                return "\(hours) hours"
            }
        } else if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else if days < 14 {
            return "1 week"
        } else if days < 30 {
            return "\(days / 7) weeks"
        } else if days < 60 {
            return "1 month"
        } else if days < 180 {
            return "\(days / 30) months"
        } else if days < 365 {
            return "6 months"
        } else {
            return "1 year"
        }
    }
} 