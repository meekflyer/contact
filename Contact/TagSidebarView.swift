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
    @Query private var tags: [Tag]
    let tag: Tag
    let contacts: [CNContact]
    var expandable = true

    @State private var tagExpanded = false
    @State private var isTargeted = false

    var body: some View {
        Section(content: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(tag.contactIDs.sorted(by: { lhs, rhs in
                            let lhsContact = contacts.getById(UUID(uuidString: lhs) ?? UUID())
                            let rhsContact = contacts.getById(UUID(uuidString: rhs) ?? UUID())
                            if let lhsContact, let rhsContact {
                                let lhsName = lhsContact.givenName + lhsContact.familyName
                                let rhsName = rhsContact.givenName + rhsContact.familyName
                                return lhsName < rhsName
                            }
                            return lhs < rhs
                        }), id: \.self) { id in
                            if let contact = contacts.getById(UUID(uuidString: id) ?? UUID()) {
                                Text(contact.givenName + " " + contact.familyName)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .draggable(contact.id)
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
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isTargeted ? .blue : .clear, lineWidth: 2)
                }
                ForEach(tags.children(of: tag)) { tag in
                    TagSidebarView(tag: tag, contacts: contacts, expandable: false)
                }
            }
            .padding(.leading, 7.5)
        }, header: {
            VStack(alignment: .leading, spacing: 0) {
                Text(tag.name)
                    .font(.subheadline)
                    .padding(.leading, 5)
                Divider()
            }
            .foregroundStyle(isTargeted ? .blue : .secondary)
            .fontWeight(.heavy)
            .draggable(UUID(uuidString: tag.id) ?? UUID()) {
                Text(tag.name)
            }
        })
        .dropDestination(for: UUID.self, action: { items, _ in
            if items.count == 1, let draggedID = items.first, let tagIndex = tags.firstIndex(where: { $0.id == draggedID.uuidString }) {
                // This is a tag
                Task {
                    await dropTag(droppedIndex: tagIndex, onto: tag)
                }
                return true
            } else {
                // This is an array of contacts
                return dropItems(items: items)
            }
        }, isTargeted: { isTargeted in
            self.isTargeted = isTargeted
        })
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func dropTag(droppedIndex tagIndex: Array<Tag>.Index, onto tag: Tag) async -> Bool {
        if !tag.isDescendent(of: tags[tagIndex], in: tags) {
            if tags.indices.contains(tagIndex) {
                tags[tagIndex].parentID = tag.id
            }
            return true
        }
        return false
    }

    private func dropItems(items: [UUID]) -> Bool {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index].contactIDs.formUnion(items.map({ $0.uuidString }))
            if let parentID = tag.parentID,
               let parentIndex = tags.firstIndex(where: { $0.id == parentID }) {
                tags[parentIndex].contactIDs.subtract(items.map({ $0.uuidString }))
            }
            let children = tags.children(of: tag)
            if !children.isEmpty {
                for child in children {
                    if let childIndex = tags.firstIndex(where: { $0.id == child.id }) {
                        tags[childIndex].contactIDs.subtract(items.map({ $0.uuidString }))
                    }
                }
            }
            return true
        }
        return false
    }
}

#Preview {
    TagSidebarView(tag: Tag(name: "Name", color: .init(red: 0, green: 0, blue: 0), parentID: nil, contactIDs: []), contacts: [])
}
