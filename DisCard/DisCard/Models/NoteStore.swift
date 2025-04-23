import Foundation
import SwiftUI

@MainActor
class NoteStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    private let saveKey = "savedNotes"
    
    init() {
        loadNotes()
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func getExpiringSoonNotes() -> [Note] {
        let calendar = Calendar.current
        let now = Date()
        return notes.filter { note in
            let components = calendar.dateComponents([.day], from: now, to: note.expiryDate)
            return components.day ?? 0 <= 7 // Notes expiring in 7 days or less
        }
    }
} 