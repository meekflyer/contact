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

    @State var tagNames: [String] = ["First Tag", "Second Tag"]
    
    @State var allContacts: [CNContact] = []
    @State var filteredContacts: [CNContact] = []
    
    @State var tagSelection = Set<UUID>()
    @State private var contactSelection = Set<UUID>()

    @State var searchString: String = ""
    @State private var currentTokens = [Tag]()
    var suggestedTokens: [Tag] {
        tags
    }

    @State private var isRootTagTargeted = false
    @State var showCreateTag = false
    @State var showEdit = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if tags.isEmpty {
                    Text("Click the + button to create your first tag!")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(selection: $tagSelection) {
                        ForEach(tags.filter({ $0.parentID == nil }), id: \.uuid) { tag in
                            TagSidebarView(tag: tag, selectedTags: $currentTokens)
                        }
                    }
                }
                VStack {
                    Spacer()
                    Button("Edit") {
                        showEdit.toggle()
                    }
                    .padding()
                    .popover(isPresented: $showEdit) {
                        EditView()
                    }
                }
            }
            .contentShape(Rectangle())
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
            .dropDestination(for: UUID.self, action: { items, _ in
                if items.count == 1, let draggedID = items.first, let tagIndex = tags.firstIndex(where: { $0.id == draggedID.uuidString }) {
                    // This is a tag
                    tags[tagIndex].parentID = nil
                }
                return false
            }, isTargeted: { isTargeted in
                self.isRootTagTargeted = isTargeted
            })
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isRootTagTargeted ? .blue : .clear, lineWidth: 2)
            }
            .onTapGesture {
                currentTokens = []
            }
        } content: {
            List(selection: $contactSelection) {
                ForEach(filteredContacts.inLetterSections(), id: \.0) { section in
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
            .contextMenu(forSelectionType: CNContact.ID.self) { items in
                Menu("Add to") {
                    ForEach(tags) { tag in
                        Button(tag.name) {
                            items.forEach { id in
                                addToTag(tag: tag, contactId: id)
                            }
                        }
                    }
                }
                Menu("Remove from") {
                    ForEach(tags.filter {
                        items.isSubset(of: $0.contactIDs.compactMap({ UUID(uuidString: $0) }))
                    }) { tag in
                        Button(tag.name) {
                            items.forEach { id in
                                removeFromTag(tag: tag, contactId: id)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchString, tokens: $currentTokens, token: { tag in
                Text(tag.name)
            })
            .searchSuggestions {
                if searchString.starts(with: "#") {
                    ForEach(tags) { tag in
                        Text(tag.name).searchCompletion(tag)
                    }
                } else {
                    ForEach(filteredContacts) { filteredContact in
                        Text("\(filteredContact.givenName) \(filteredContact.familyName)")
                            .searchCompletion("\(filteredContact.givenName) \(filteredContact.familyName)")
                    }
                }
            }
            .listStyle(.plain)
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #elseif os(iOS)
            #endif
        } detail: {
            Group {
                if let id = Array(contactSelection).last, let contact = filteredContacts.getById(id) {
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
        .onChange(of: currentTokens) { _, _ in
            filterContactsByTags()
        }
        .onChange(of: searchString) { _, _ in
            filterContactsBySearchString()
        }
        .onChange(of: tagSelection) { _, newValue in
            currentTokens = tags.filter { newValue.contains($0.uuid) }
        }
        .onChange(of: currentTokens) { _, newValue in
            tagSelection = Set(newValue.map { $0.uuid })
        }
    }

    private func filterContactsByTags() {
        guard !currentTokens.isEmpty else {
            filteredContacts = allContacts
            return
        }
        let filteredContactIds = Set<String>(
            currentTokens.flatMap { tag in
                tag.getContactIDsWithDescendents(from: tags)
            }
        )
        withAnimation {
            filteredContacts = allContacts.filter { contact in
                filteredContactIds.contains(contact.id.uuidString)
            }
        }
    }

    private func filterContactsBySearchString() {
        filterContactsByTags()
        if !searchString.isEmpty {
            withAnimation {
                filteredContacts = filteredContacts.filter { contact in
                    (String(describing: contact) + "\(contact.givenName) \(contact.familyName))")
                        .lowercased()
                        .contains(searchString.lowercased())
                }
                if filteredContacts.count == 1, let first = filteredContacts.first {
                    contactSelection.removeAll()
                    contactSelection.insert(first.id)
                }
            }
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
        
        self.allContacts = contacts
        self.filteredContacts = contacts
    }

    func addToTag(tag: Tag, contactId: UUID) {
        if let index = tags.firstIndex(of: tag) {
            self.tags[index].contactIDs.insert(contactId.uuidString)
        }
    }

    func removeFromTag(tag: Tag, contactId: UUID) {
        if let index = tags.firstIndex(of: tag) {
            self.tags[index].contactIDs.remove(contactId.uuidString)
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
        
        for section in sections {
            sections[section.key] = sections[section.key]?.sorted()
        }
        
        return sections.sorted { $0.key < $1.key }
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
