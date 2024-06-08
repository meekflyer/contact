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
                VStack {
                    HStack {
                        Text(tag.name)
                            .foregroundStyle(.primary)
                            .bold()
                        Spacer()

                        Button("Delete") {
                            deleteTag(tag)
                        }
                    }
                    if let last = tags.last, tag != last {
                        Divider()
                    }
                }
            }
            .safeAreaPadding(5)
            .frame(width: 500, height: 200)
            .listStyle(.sidebar)
        }
    }

    private func deleteTag(_ tag: Tag) {
        withAnimation {
            tags.children(of: tag).forEach { childTag in
                modelContext.delete(childTag)
            }
            modelContext.delete(tag)
        }
    }
}

#Preview {
    EditView()
}
