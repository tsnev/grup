//
//  CollectionDetailView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//


import Foundation
import CoreData
import SwiftUI
import PhotosUI

struct CollectionDetailView: View {
    @ObservedObject var collection: ItemCollection
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var refreshID: UUID
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var isEditing = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingDeleteConfirmation = false
    
    var filteredItems: [Item] {
        let items = collection.items?.allObjects as? [Item] ?? []
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                (item.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.desc?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.tradeKeepStatus?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            if !isEditing {
                if let imageData = collection.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Section(header: Text("Collection Image")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let imageData = selectedImageData ?? collection.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ContentUnavailableView("No Image Selected",
                                systemImage: "photo.badge.plus",
                                description: Text("Tap to select an image"))
                        }
                    }
                }
                
                Section {
                    Button("Delete Collection", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
            
            ForEach(filteredItems, id: \.self) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ItemRowView(item: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .searchable(text: $searchText, prompt: "Search items")
        .navigationTitle(collection.name ?? "")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button(action: { showingAddItem = true }) {
                            Label("Add Item", systemImage: "plus")
                        }
                        
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(collection: collection)
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this collection?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteCollection()
            }
        } message: {
            Text("This will permanently delete this collection and all its items.")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
    
    private func deleteCollection() {
        withAnimation {
            viewContext.delete(collection)
            try? viewContext.save()
            dismiss()
        }
    }
    
    private func startEditing() {
        selectedImageData = collection.imageData
        isEditing = true
    }
    
    private func cancelEditing() {
        selectedImageData = nil
        isEditing = false
    }
    
    private func saveChanges() {
        withAnimation {
            if let newImageData = selectedImageData {
                collection.imageData = newImageData
                try? viewContext.save()
                
                refreshID = UUID()
            }
            isEditing = false
        }
    }
}
