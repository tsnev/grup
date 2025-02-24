//
//  AddItemView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import SwiftUI
import PhotosUI
import CoreData

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var collection: ItemCollection  // Changed to @ObservedObject
    
    @State private var title = ""
    @State private var desc = ""
    @State private var tradeKeepStatus = "Keep"
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageSourceOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingError = false
    
    let tradeKeepOptions = ["Keep", "Trade", "Undecided"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $desc)
                    Picker("Status", selection: $tradeKeepStatus) {
                        ForEach(tradeKeepOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Item Image")) {
                    Button(action: {
                        showingImageSourceOptions = true
                    }) {
                        HStack {
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ContentUnavailableView("No Image Selected",
                                    systemImage: "photo.badge.plus",
                                    description: Text("Tap to select an image"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .confirmationDialog(
                "Choose Image Source",
                isPresented: $showingImageSourceOptions,
                titleVisibility: .visible
            ) {
                Button("Photo Library") {
                    showingPhotoPicker = true
                }
                
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Camera") {
                        showingCamera = true
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(imageData: $selectedImageData)
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("There was an error saving the item. Please try again.")
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.title = title
            newItem.desc = desc
            newItem.tradeKeepStatus = tradeKeepStatus
            newItem.imageData = selectedImageData
            newItem.parentCollection = collection
            
            do {
                try viewContext.save()
                collection.objectWillChange.send()  // Notify the collection of changes
                dismiss()
            } catch {
                // If saving fails, show error and rollback changes
                showingError = true
                viewContext.rollback()
            }
        }
    }
}

#Preview {
    AddItemView(collection: ItemCollection())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
