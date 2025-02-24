//
//  Persistence.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import CoreData

struct PersistenceController {
    // Shared instance for accessing throughout the app
    static let shared = PersistenceController()

    // Storage for Core Data preview in SwiftUI
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleCollection = ItemCollection(context: viewContext)
        sampleCollection.name = "Sample Collection"
        sampleCollection.timestamp = Date()
        sampleCollection.imageData = nil
        
        let sampleItem = Item(context: viewContext)
        sampleItem.title = "Sample Item"
        sampleItem.desc = "This is a sample description"
        sampleItem.timestamp = Date()
        sampleItem.tradeKeepStatus = "Keep"
        sampleItem.parentCollection = sampleCollection
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    // Core Data container
    let container: NSPersistentContainer

    // Initialize the persistent container
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "cursorCollection")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Optional: Configure saving behavior
        configureContextSaving()
    }
    
    // Configure automatic saving of the context
    private func configureContextSaving() {
        let center = NotificationCenter.default
        let notification = Notification.Name.NSManagedObjectContextDidSave
        
        center.addObserver(forName: notification, object: nil, queue: nil) { _ in
            self.save()
        }
    }
    
    // Save changes if there are any
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Delete all records of a specific entity
    func deleteAll(_ entityName: String) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
    
    // Create a background context for performing operations off the main thread
    func backgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

// Extension to help with managing Core Data operations
extension PersistenceController {
    // Perform work in background
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext()
        context.perform {
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Error saving background context: \(error)")
                }
            }
        }
    }
}
