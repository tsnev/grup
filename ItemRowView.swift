//
//  ItemRowView.swift
//  cursorCollection
//
//  Created by tyler snevel on 2/9/25.
//

import Foundation
import SwiftUI

struct ItemRowView: View {
    @ObservedObject var item: Item
    
    var body: some View {
        HStack {
            if let imageData = item.imageData,
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
            
            VStack(alignment: .leading) {
                Text(item.title ?? "Untitled")
                    .font(.headline)
                Text(item.tradeKeepStatus ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(item.desc ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
