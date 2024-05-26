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
    
    @State var draggedItems: [String] = []
    
    @State var contacts: [CNContact] = []
    @State private var selection = Set<UUID>()
    @State var searchString: String = ""
    
    var body: some View {
        HStack {
            List(draggedItems, id: \.self) { item in
                Text(item)
                Spacer()
            }
            .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                for provider in providers {
                    provider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
                        if let error {
                            print(error)
                        } else {
                            draggedItems.append(String(data: data ?? "".data(using: .utf8)!, encoding: .utf8) ?? "")
                        }
                    }
                }
                return true
            }
            .frame(width: 150)
            .listStyle(.sidebar)
            NavigationSplitView {
                List {
                    ForEach(contacts.sorted(by: { lhs, rhs in
                        lhs.givenName < rhs.givenName
                    }), id: \.id) { item in
                        NavigationLink {
                            ContactDetailView(contact: item)
                        } label: {
                            Text(item.givenName).bold() + Text(" ") + Text(item.familyName)
                        }
                        .onDrag {
                            return NSItemProvider(object: item.givenName as NSString)
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
