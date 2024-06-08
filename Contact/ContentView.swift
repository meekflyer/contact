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
    @Query private var tags: [Tag]
    
    @State var openContact: CNContact?
    @State var tagNames: [String] = ["First Tag", "Second Tag"]
    
    @State var contacts: [CNContact] = []
    @State private var selection = Set<UUID>()
    @State var searchString: String = ""

    @State var showCreateTag = false
    @State var showEdit = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if tags.isEmpty {
                    Text("Click the + button to create your first tag!")
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(tags.filter({ $0.parentID == nil }), selection: $selection) { tag in
                        TagSidebarView(tag: tag, contacts: contacts)
                    }
                }
                Button("Edit") {
                    showEdit.toggle()
                }
                .padding()
                .popover(isPresented: $showEdit) {
                    EditView()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showCreateTag.toggle() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .popover(isPresented: $showCreateTag, arrowEdge: .bottom) {
                        CreateTagView(closeView: {
                            showCreateTag = false
                        })
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
