//
//  ContentView.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
//

import SwiftUI
import SwiftData
import Contacts

struct ContentView: View {
    @Environment(\.self) var environment
    @Environment(\.modelContext) private var modelContext
//    @Query private var tags: [Tag]
    @State private var tags: [Tag] = []
    
    @State var openContact: CNContact?
    @State var tagNames: [String] = ["First Tag", "Second Tag"]
    @State var tagExpanded: [String : Bool] = [:]
    
    @State var contacts: [CNContact] = []
    @State private var selection = Set<UUID>()
    @State var searchString: String = ""
    
    var body: some View {
        NavigationSplitView {
            List(tags, selection: $selection) { tag in
                Section(isExpanded: .init(
                    get: {
                        if let expanded = tagExpanded[tag.id] {
                            return expanded
                        } else {
                            tagExpanded[tag.id] = false
                            return false
                        }
                    },
                    set: { expanded in
                        tagExpanded[tag.id] = expanded
                    }
                ), content: {
                    VStack(alignment: .leading) {
                        ForEach(tag.contactIDs, id: \.self) { id in
                            if let contact = contacts.getById(UUID(uuidString: id) ?? UUID()) {
                                Text(contact.givenName)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No name")
                            }
                        }
                        .padding(.leading, 5)
                    }
                }, header: {
                    Text("\(tag.name) (\(tag.contactIDs.count))")
                })
                .contentShape(Rectangle())
                .dropDestination(for: UUID.self) { items, location in
                    withAnimation(.linear) {
                        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
                            tags[index].contactIDs.append(contentsOf: items.map({ $0.uuidString }))
                        }
                    }
                    return true
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {}) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 175, ideal: 175)
            #endif
        } content: {
            List(selection: $selection) {
                ForEach(contacts.inLetterSections(), id: \.0) { section in
                    Section(String(section.0)) {
                        ForEach(section.1) { contact in
                            Group {
                                Text(contact.givenName).bold() + Text(" ") + Text(contact.familyName)
                            }
                            .draggable(contact.id) {
                                Text("\(contact.givenName) \(contact.familyName)")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchString)
            .listStyle(.plain)
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #elseif os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            #endif
        } detail: {
            Group {
                if let id = Array(selection).last, let contact = contacts.getById(id) {
                    ContactDetailView(contact: contact)
                } else {
                    Text("Select an item")
                }
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 300, ideal: 500)
            #endif
        }
        .task {
            await fetchContacts()
        }
        .onAppear {
            tags.append(Tag(name: "Test Tag", color: Color.green.resolve(in: environment), contactIDs: []))
        }
    }
    
    private func fetchContacts() async {
        var contacts = [CNContact]()
        let keysToFetch = [
            CNContactNamePrefixKey,
            CNContactGivenNameKey,
            CNContactMiddleNameKey,
            CNContactFamilyNameKey,
            CNContactPreviousFamilyNameKey,
            CNContactNameSuffixKey,
            CNContactNicknameKey,
            CNContactOrganizationNameKey,
            CNContactDepartmentNameKey,
            CNContactJobTitleKey,
            CNContactPhoneticGivenNameKey,
            CNContactPhoneticMiddleNameKey,
            CNContactPhoneticFamilyNameKey,
            CNContactPhoneticOrganizationNameKey,
            CNContactBirthdayKey,
            CNContactNonGregorianBirthdayKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataAvailableKey,
            CNContactTypeKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactDatesKey,
            CNContactUrlAddressesKey,
            CNContactRelationsKey,
            CNContactSocialProfilesKey,
            CNContactInstantMessageAddressesKey
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        let contactStore = CNContactStore()
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
        
        self.contacts = contacts
    }

//    private func addItem(name: String, color: Color, parentID: String? = nil) {
//        withAnimation {
//            let newItem = Tag(name: name, color: color.resolve(in: environment), parentID: parentID)
//            modelContext.insert(newItem)
//        }
//    }

//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(tags[index])
//            }
//        }
//    }
}

extension CNContact: Comparable {
    public static func < (lhs: CNContact, rhs: CNContact) -> Bool {
        lhs.givenName < rhs.givenName
    }
}

extension [CNContact] {
    func inLetterSections() -> [(Character, [CNContact])] {
        var sections: [Character : [CNContact]] = ["#" : []]
        
        for contact in self {
            if let firstLetter = contact.givenName.first?.uppercased().first {
                if firstLetter.isLetter {
                    if sections[firstLetter] != nil {
                        sections[firstLetter]?.append(contact)
                    } else {
                        sections[firstLetter] = []
                        sections[firstLetter]?.append(contact)
                    }
                } else {
                    sections["#"]?.append(contact)
                }
            } else {
                sections["#"]?.append(contact)
            }
        }
        
        if let miscValues = sections["#"], miscValues.isEmpty {
            sections.removeValue(forKey: "#")
        }
        
        for section in sections {
            sections[section.key] = sections[section.key]?.sorted()
        }
        
        return sections.sorted { $0.0 < $1.0 }
    }
    
    func getById(_ id: UUID) -> CNContact? {
        self.first(where: { $0.id == id })
    }
}

extension UUID: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Tag.self, inMemory: true)
}
