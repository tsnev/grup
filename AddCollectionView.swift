//
//  AddCollectionView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct AddCollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageSourceOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Details")) {
                    TextField("Collection Name", text: $name)
                }
                
                Section(header: Text("Collection Image")) {
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
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCollection()
                    }
                    .disabled(name.isEmpty)
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
        }
    }
    
    private func addCollection() {
        withAnimation {
            let newCollection = ItemCollection(context: viewContext)
            newCollection.timestamp = Date()
            newCollection.name = name
            newCollection.imageData = selectedImageData
            
            try? viewContext.save()
            dismiss()
        }
    }
}
