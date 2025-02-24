//
//  ItemDetailView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var item: Item
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    // Editing states
    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @State private var editedTradeKeepStatus: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    let tradeKeepOptions = ["Keep", "Trade", "Undecided"]
    
    var body: some View {
        Form {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .navigationTitle(isEditing ? "Edit Item" : (item.title ?? ""))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Menu {
                            Button("Edit") {
                                startEditing()
                            }
                            Button("Delete", role: .destructive) {
                                showingDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this item?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        }
    }
    
    private var displayView: some View {
        Group {
            Section {
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Section(header: Text("Details")) {
                LabeledContent("Title", value: item.title ?? "")
                LabeledContent("Status", value: item.tradeKeepStatus ?? "")
                if let description = item.desc, !description.isEmpty {
                    Text(description)
                }
            }
        }
    }
    
    private var editingView: some View {
        Group {
            Section(header: Text("Image")) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let imageData = selectedImageData ?? item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } else {
                        ContentUnavailableView("No Image Selected",
                            systemImage: "photo.badge.plus",
                            description: Text("Tap to select an image"))
                    }
                }
            }
            
            Section(header: Text("Details")) {
                TextField("Title", text: $editedTitle)
                TextField("Description", text: $editedDescription, axis: .vertical)
                Picker("Status", selection: $editedTradeKeepStatus) {
                    ForEach(tradeKeepOptions, id: \.self) {
                        Text($0)
                    }
                }
            }
        }
    }
    
    private func startEditing() {
        editedTitle = item.title ?? ""
        editedDescription = item.desc ?? ""
        editedTradeKeepStatus = item.tradeKeepStatus ?? "Keep"
        selectedImageData = item.imageData
        isEditing = true
    }
    
    private func saveChanges() {
        item.title = editedTitle
        item.desc = editedDescription
        item.tradeKeepStatus = editedTradeKeepStatus
        if let newImageData = selectedImageData {
            item.imageData = newImageData
        }
        
        try? viewContext.save()
        isEditing = false
    }
    
    private func deleteItem() {
        viewContext.delete(item)
        try? viewContext.save()
        dismiss()
    }
}
