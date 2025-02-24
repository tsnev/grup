//
//  cursorCollectionApp.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import SwiftUI

@main
struct cursorCollectionApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
