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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State var tagNames: [String] = ["First Tag", "Second Tag"]
    @State var draggedItems: [String:[String]] = ["First Tag":[], "Second Tag":[]]
    
    @State var contacts: [CNContact] = []
    @State private var selection = Set<UUID>()
    @State var searchString: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            List(tagNames, id: \.self) { tag in
                VStack(alignment: .leading) {
                    Text(tag)
                    ForEach(draggedItems[tag] ?? [], id: \.self) { name in
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 5)
                }
                .dropDestination(for: String.self) { items, location in
                    for item in items {
                        withAnimation(.linear) {
                            draggedItems[tag]?.append(item)
                        }
                    }
                    return true
                }
            }
            .frame(width: 150)
            .listStyle(.sidebar)
            NavigationSplitView {
                List {
                    ForEach(contacts.inLetterSections(), id: \.0) { section in
                        Section {
                            ForEach(section.1) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    Group {
                                        Text(contact.givenName).bold() + Text(" ") + Text(contact.familyName)
                                    }
                                }
                                .draggable(contact.givenName) {
                                    Text("\(contact.givenName) \(contact.familyName)")
                                }
                            }
                        } header: {
                            Text(String(section.0))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .searchable(text: $searchString)
                .listStyle(.plain)
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
                #endif
                .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                #endif
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
        }
        .task {
            await fetchContacts()
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

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
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
        
        return sections.sorted { $0.0 < $1.0 }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
