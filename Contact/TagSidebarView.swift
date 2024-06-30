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

    @Binding var allContacts: [CNContact]
    @State private var isTargeted = false

    var body: some View {
        Group {
            if tags.children(of: tag).isEmpty {
                header
            } else {
                DisclosureGroup(
                    content: {
                        ForEach(tags.children(of: tag), id: \.uuid) { tag in
                            TagSidebarView(tag: tag, allContacts: $allContacts)
                        }
                    },
                    label: {
                        header
                    }
                )
            }
        }
        .dropDestination(for: UUID.self, action: { items, _ in
            let itemsSet = Set(items)
            if itemsSet.isSubset(of: tags.map { $0.uuid }) {
                return dropTags(dropping: items, onto: tag)
            } else if itemsSet.isSubset(of: allContacts.map({ $0.id })) {
                return dropContacts(dropping: items, onto: tag)
            }
            return false
        }, isTargeted: { isTargeted in
            self.isTargeted = isTargeted
        })
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    var header: some View {
        Group {
            Text("\(tag.name)").bold() + Text(" (\(tag.getContactIDsWithDescendents(from: tags).count))")
        }
        .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
        .draggable(tag.uuid) {
            Text(tag.name)
        }
    }

    @MainActor
    private func dropTags(dropping items: [UUID], onto tag: Tag) -> Bool {
        var successFlag = false
        items.forEach { tagId in
            if let tagIndex = tags.firstIndex(where: { $0.uuid == tagId }),
               !tag.isDescendent(of: tags[tagIndex], in: tags) &&
                tags.indices.contains(tagIndex) {
                tags[tagIndex].parentID = tag.id
                successFlag = true
            }
        }
        return successFlag
    }
    
    @MainActor
    private func dropContacts(dropping items: [UUID], onto tag: Tag) -> Bool {
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else { return false }

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
}

#Preview {
    TagSidebarView(tag: Tag(name: "Name", color: .init(red: 0, green: 0, blue: 0), parentID: nil, contactIDs: []), allContacts: .constant([]))
}
