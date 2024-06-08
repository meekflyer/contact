//
//  EditView.swift
//  Contact
//
//  Created by Thomas Patrick on 6/8/24.
//

import SwiftUI
import SwiftData

struct EditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    
    var body: some View {
        VStack {
            List(tags) { tag in
                HStack {
                    Text(tag.name)
                        .foregroundStyle(.primary)
                        .bold()
                    Spacer()
                    Button("Delete") {
                        deleteTag(tag)
                    }
                }
            }
            .padding()
            .frame(width: 200, height: 250)
            .listStyle(.sidebar)
        }
    }

    private func deleteTag(_ tag: Tag) {
        withAnimation {
            tags.filter({ $0.parentID == tag.id }).forEach { childTag in
                modelContext.delete(childTag)
            }
            modelContext.delete(tag)
        }
    }
}

#Preview {
    EditView()
}
