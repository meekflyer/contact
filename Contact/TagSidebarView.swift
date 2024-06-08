//
//  TagSidebarView.swift
//  Contact
//
//  Created by Thomas Patrick on 6/5/24.
//

import SwiftUI
import SwiftData
import Contacts

struct TagSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    let tag: Tag
    let contacts: [CNContact]
    var expandable = true

    @State private var tagExpanded = false

    var body: some View {
        Section(content: {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(tag.contactIDs, id: \.self) { id in
                    if let contact = contacts.getById(UUID(uuidString: id) ?? UUID()) {
                        Text(contact.givenName)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        if contacts.isEmpty {
                            Text("Loading...")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No name")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                ForEach(tags.filter({ $0.parentID == tag.id })) { tag in
                    TagSidebarView(tag: tag, contacts: contacts, expandable: false)
                }
            }
            .padding(.leading, 5)
        }, header: {
            Text("\(tag.name) (\(tag.contactIDs.count))")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .fontWeight(.heavy)
        })
        .dropDestination(for: UUID.self) { items, location in
            withAnimation(.linear) {
                if let index = tags.firstIndex(where: { $0.id == tag.id }) {
                    tags[index].contactIDs.append(contentsOf: items.map({ $0.uuidString }))
                }
            }
            return true
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    TagSidebarView(tag: Tag(name: "Name", color: .init(red: 0, green: 0, blue: 0), parentID: nil, contactIDs: []), contacts: [])
}
