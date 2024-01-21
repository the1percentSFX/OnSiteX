//
//  ContentView.swift
//  OnSiteX
//
//  Created by Victor Ramirez on 1/20/24.
//

//
//  ContentView.swift
//  OnSite
//
//  Created by Victor Ramirez on 1/17/24.
//

import Foundation

import SwiftUI

enum NoteType {
    case regular
    case chat
}
    
enum Sender {
    case user
    case chat
}

struct Note: Identifiable {
    let id: UUID
    var title: String
    var detail: String
    var date: Date
    var type: NoteType
    var sender: Sender
    
}

struct HomeView: View {
    @Binding var notes: [Note]
    @State private var noteText: String = ""
    @State private var isChatPresented = false

    var body: some View {
        VStack {
                    Spacer()
                    
                    List {
                        ForEach(notes) { note in
                            VStack(alignment: .leading) {
                                Text(note.title)
                                    .font(.headline)
                                Text(note.detail)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Type your note here...", text: $noteText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addNote) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(noteText.isEmpty)
                                        Button(action: {
                    startChat()
                }) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
        }
        .navigationTitle("OnSite")
        .sheet(isPresented: $isChatPresented) {
        }
    }

    private func addNote() {
        let newNote = Note(id: UUID(), title: "Me", detail: noteText, date: Date(), type: .regular, sender: .user)
                notes.append(newNote)
                noteText = ""
    }

    private func startChat() {
        guard !noteText.isEmpty else { return }
        
        // Simulate sending the user's message first
        let userNote = Note(id: UUID(), title: "Me", detail: noteText, date: Date(), type: .chat, sender: .user)
        self.notes.append(userNote)
        
        OpenAIService.shared.sendMessage(noteText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let chatNote = Note(id: UUID(), title: "OnSite", detail: response, date: Date(), type: .chat, sender: .chat)
                    self.notes.append(chatNote)
                        
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
                self.noteText = ""
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var notes: [Note] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(notes: $notes)
            }
            .tabItem {
                Image(systemName: Tab.home.iconName)
                Text("OnSite")
            }
            .tag(Tab.home)
            
            NavigationStack {
                CalendarView(notes: $notes)
            }
            .tabItem {
                Image(systemName: Tab.calendar.iconName)
                Text("Calender")
            }
            .tag(Tab.calendar)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

enum Tab {
    case home
    case calendar
    
    var iconName: String {
        switch self {
        case .home:
            return "house"
        case .calendar:
            return "calendar"
        }
    }
}
struct CalendarView: View {
    @Binding var notes: [Note]
    @State private var selectedDate = Date()
    @State private var showingDetail = false
    @State private var selectedNote: Note?
    
    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
            
            List(notes.filter { shouldDisplay(note: $0) }) { note in
                Button(action: {
                    self.selectedNote = note
                    self.showingDetail.toggle()
                }) {
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.detail)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .sheet(isPresented: $showingDetail) {
            if let selectedNote = selectedNote {
                NoteDetailView(note: selectedNote)
            }
        }
    }

    private func shouldDisplay(note: Note) -> Bool {
        return Calendar.current.isDate(note.date, inSameDayAs: selectedDate) && (note.type == .regular || note.type == .chat)
    }
}

struct NoteDetailView: View {
    var note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(note.title)
                .font(.largeTitle)
            Text(note.detail)
                .font(.title2)
            Spacer()
        }
        .padding()
        .navigationTitle("Note Details")
    }
}
