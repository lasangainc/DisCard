//
//  DisCardApp.swift
//  DisCard
//
//  Created by Benji on 2025-04-23.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.windows.forEach { window in
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            
            if let windowController = window.windowController {
                windowController.window?.titleVisibility = .hidden
                windowController.window?.titlebarAppearsTransparent = true
                windowController.window?.standardWindowButton(.closeButton)?.isHidden = false
                windowController.window?.standardWindowButton(.miniaturizeButton)?.isHidden = false
                windowController.window?.standardWindowButton(.zoomButton)?.isHidden = false
            }
        }
    }
}

@main
struct DisCardApp: App {
    @StateObject private var noteStore = NoteStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(noteStore)
                .background(.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 400)
    }
}
