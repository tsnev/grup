//
//  ContentView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingAddCollection = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ItemCollection.timestamp, ascending: true)],
        animation: .default
    ) private var collections: FetchedResults<ItemCollection>
    
    var filteredCollections: [ItemCollection] {
        if searchText.isEmpty {
            return Array(collections)
        } else {
            return collections.filter { $0.name?.localizedCaseInsensitiveContains(searchText) ?? false }
        }
    }
    
    var body: some View {
        NavigationView {
            MainContentView(
                collections: filteredCollections,
                searchText: $searchText,
                showingAddCollection: $showingAddCollection,
                deleteCollections: deleteCollections
            )
        }
    }
    
    private func deleteCollections(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredCollections[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}


// Main content view
struct MainContentView: View {
    let collections: [ItemCollection]
    @Binding var searchText: String
    @Binding var showingAddCollection: Bool
    let deleteCollections: (IndexSet) -> Void
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            List {
                ForEach(collections, id: \.self) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection, refreshID: $refreshID)) {
                        CollectionRowView(collection: collection)
                    }
                }
                .onDelete(perform: deleteCollections)
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCollection = true }) {
                    Label("Add Collection", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            AddCollectionView()
        }
    }
}

struct LogoView: View {
    var body: some View {
        Image("top_logo") // Replace with your logo name
            .resizable()
            .scaledToFit()
            .frame(height: 30) // Reduced height to fit in navigation bar
    }
}

// Custom SearchBar view
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search collections", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
        }
    }
}

//struct LogoView: View {
  //  var body: some View {
    //    Image("top_logo") // Replace with your logo name
      //      .resizable()
        //    .scaledToFit()
          //  .frame(height: 15)
            //.frame(maxWidth: .infinity)
            //.padding(.bottom, 6)
            //.background(Color(UIColor.systemBackground))
   // }
//}

struct CollectionRowView: View {
    let collection: ItemCollection
    
    var body: some View {
        HStack {
            if let imageData = collection.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(collection.name ?? "Unnamed Collection")
                .padding(.leading, 8)
        }
    }
}
