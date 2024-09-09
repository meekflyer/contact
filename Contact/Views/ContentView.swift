//
//  ContentView.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
//

import Contacts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]

    @State var tagNames: [String] = []
    
    @State var allContacts: [CNContact] = []
    @State var filteredContacts: [CNContact] = []
    @State var lists: [ContactList] = []

    @State var tagSelection = Set<UUID>()
    @State private var contactSelection = Set<UUID>()

    @State var searchString: String = ""
    @State private var currentTokens = [Token]()
    var suggestedTokens: [Token] {
        var tokens = [Token]()
        tags.forEach { tag in
            tokens.append(Token(tag))
        }
        lists.forEach { list in
            tokens.append(Token(list))
        }
        return tokens
    }
    
    @State private var targetedContactId: UUID?
    @State private var isRootTagTargeted = false
    @State private var showCreateTag = false
    @State private var showEdit = false
    @State private var showMap = false
    @State private var loading = false

    var body: some View {
        NavigationSplitView {
            leftBar
        } content: {
            ZStack {
                middleBar.opacity(loading ? 0 : 1)
                if loading {
                    ProgressView()
                }
            }
        } detail: {
            rightBar
        }
        .task {
            await fetchContacts()
        }
        .onChange(of: currentTokens) { _, newValue in
            filterContactsByTags()
            tagSelection = Set(newValue.map { $0.uuid })
        }
        .onChange(of: searchString) { _, _ in
            filterContactsBySearchString()
        }
        .onChange(of: tagSelection) { _, newValue in
            let filteredTags = tags.filter {
                newValue.contains($0.uuid)
            }
            let filteredLists = lists.filter {
                newValue.contains($0.uuid)
            }
            let allGroups = filteredTags.map({ Token($0) }) + filteredLists.map({ Token($0) })
            currentTokens = allGroups
        }
    }

    private var leftBar: some View {
        VStack {
            if !lists.isEmpty {
                VStack {
                    Text("Lists")
                        .font(.title2)
                        .bold()
                    Text("Create and edit Lists in the default Contacts app")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    List(selection: $tagSelection) {
                        ForEach(lists, id: \.uuid) { list in
                            VStack {
                                Text("\(list.name)").bold() + Text(" (\(list.contactIDs.count))")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxHeight: 100)
                }
                .transition(.slide)
            }
            VStack {
                Text("Tags")
                    .font(.title2)
                    .bold()
                if tags.isEmpty {
                    Text("Click the + button to create your first tag!")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(selection: $tagSelection) {
                        ForEach(tags.filter({ $0.parentID == nil }), id: \.uuid) { tag in
                            TagSidebarView(tag: tag, allContacts: $allContacts)
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
            .dropDestination(for: UUID.self, action: { items, _ in
                if Set(items).isSubset(of: tags.map { $0.uuid }) {
                    // These are tags
                    items.forEach { tagId in
                        if let tagIndex = tags.firstIndex(where: { $0.uuid == tagId }) {
                            tags[tagIndex].parentID = nil
                        }
                    }
                }
                return false
            }, isTargeted: { isTargeted in
                self.isRootTagTargeted = isTargeted
            })
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isRootTagTargeted ? .blue : .clear, lineWidth: 2)
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
        .onTapGesture {
            currentTokens = []
        }
    }

    private var middleBar: some View {
        List(selection: $contactSelection) {
            ForEach(filteredContacts.inLetterSections(), id: \.0) { section in
                Section(String(section.0)) {
                    ForEach(section.1) { contact in
                        Group {
                            Text(contact.givenName).bold() + Text(" ") + Text(contact.familyName)
                        }
                        .foregroundStyle(targetedContactId == contact.id ? Color.accentColor : Color.primary)
                        .draggable(contact.id) {
                            Text(contact.fullName)
                        }
                        .dropDestinationForTags(tags: tags, contact: contact, targetedContactId: $targetedContactId)
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
                    Text(filteredContact.fullName)
                        .searchCompletion(filteredContact.fullName)
                }
            }
        }
        .listStyle(.plain)
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        #endif
    }

    private var rightBar: some View {
        Group {
            if showMap {
                ContactMapView(contacts: .init(get: {
                    contactSelection.compactMap({ id in
                        allContacts.getById(id)
                    })
                }, set: { _ in }))
                .transition(.move(edge: .top))
            }
            else if let id = Array(contactSelection).last,
                        let contact = allContacts.getById(id) {
                ContactDetailView(contact: contact)
            } else {
                Text("Select an item")
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { withAnimation { showMap.toggle() } }) {
                    Label("Show map", systemImage: showMap ? "map.fill" : "map")
                }
            }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 300, ideal: 500)
        #endif
    }

    private func filterContactsByTags() {
        guard !currentTokens.isEmpty else {
            filteredContacts = allContacts
            return
        }
        let filteredContactIds = Set<String>(
            currentTokens.flatMap { token in
                token.getContactIds(tags: tags)
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
                    (String(describing: contact) + contact.fullName)
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
        await MainActor.run {
            self.loading = true
        }
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
            try contactStore.groups(matching: nil).forEach { group in
                let predicate = CNContact.predicateForContactsInGroup(
                    withIdentifier: group.identifier
                )
                let contactsInGroup = try contactStore.unifiedContacts(
                    matching: predicate,
                    keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]
                )
                lists.append(ContactList(
                    id: group.identifier,
                    name: group.name,
                    contactIDs: Set(contactsInGroup.map { $0.id.uuidString })
                ))
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }

        let fetchedContacts = contacts
        await MainActor.run {
            withAnimation(.bouncy) {
                self.allContacts = fetchedContacts
                self.filteredContacts = fetchedContacts
                self.loading = false
            }
        }
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

    var fullName: String {
        "\(givenName) \(familyName)"
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

extension View {
    func dropDestinationForTags(tags: [Tag], contact: CNContact, targetedContactId: Binding<UUID?>) -> some View {
        self.dropDestination(for: UUID.self, action: { items, _ in
            if Set(items).isSubset(of: tags.map { $0.uuid }) {
                // These are tags
                items.forEach { tagId in
                    if let tagIndex = tags.firstIndex(where: { $0.uuid == tagId }) {
                        tags[tagIndex].contactIDs.insert(contact.id.uuidString)
                    }
                }
                return true
            }
            return false
        }, isTargeted: { isTargeted in
            if isTargeted {
                targetedContactId.wrappedValue = contact.id
            } else {
                targetedContactId.wrappedValue = nil
            }
        })
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Tag.self, inMemory: true)
}
