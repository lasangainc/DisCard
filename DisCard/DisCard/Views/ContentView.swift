import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var noteStore: NoteStore
    @State private var showingAddNote = false
    @State private var showingExpiringSoon = false
    @State private var selectedNote: Note?
    
    private let columns = [
        GridItem(.fixed(160), spacing: 20),
        GridItem(.fixed(160), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            // Background frosted glass effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            NavigationStack {
                Group {
                    if displayedNotes.isEmpty {
                        VStack {
                            Spacer()
                            if showingExpiringSoon {
                                Text("Notes that expire soon will show up here")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            } else {
                                Text("Write a note!")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        ScrollView(showsIndicators: true) {
                            VStack {
                                Spacer(minLength: 40)
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(displayedNotes) { note in
                                        NoteView(note: note)
                                            .transition(
                                                .asymmetric(
                                                    insertion: .scale.combined(with: .opacity),
                                                    removal: .scale.combined(with: .opacity)
                                                )
                                            )
                                    }
                                }
                                .padding(20)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayedNotes)
                                Spacer()
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingExpiringSoon.toggle()
                        } label: {
                            Image(systemName: showingExpiringSoon ? "clock.fill" : "clock")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Floating add note button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingAddNote = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 400, height: 400)
        .fixedSize()
        .overlay {
            if showingAddNote {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    FloatingNoteEditor(isShowing: $showingAddNote)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(note: note, isEditing: true)
        }
    }
    
    private var displayedNotes: [Note] {
        showingExpiringSoon ? noteStore.getExpiringSoonNotes() : noteStore.notes
    }
}

struct FloatingNoteEditor: View {
    @EnvironmentObject private var noteStore: NoteStore
    @Binding var isShowing: Bool
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedExpiryOption: NoteEditorView.ExpiryOption = .hour
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Note")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 8)
            
            TextField("Title", text: $title)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            ScrollView {
                TextField("Content", text: $content, axis: .vertical)
                    .font(.body)
                    .lineLimit(5...)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 100)
            
            Spacer()
            
            HStack {
                Text("Expires in")
                    .font(.subheadline)
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
                    saveNote()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowing = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(.blue)
                .disabled(title.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300, height: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.regularMaterial)
                .shadow(radius: 10)
        )
    }
    
    private func saveNote() {
        let expiryDate = Date().addingTimeInterval(selectedExpiryOption.timeInterval)
        
        let newNote = Note(
            title: title,
            content: content,
            expiryDate: expiryDate
        )
        
        noteStore.addNote(newNote)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
} 