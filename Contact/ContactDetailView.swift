//
//  ContactDetailView.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
//

import SwiftUI
import Contacts

struct ContactDetailView: View {
    let contact: CNContact
    let dateFormatter: DateFormatter
    @State var profileImage = Image(systemName: "person.fill")
    
    init(contact: CNContact, profileImage: SwiftUI.Image = Image(systemName: "person.fill")) {
        self.contact = contact
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        self.profileImage = profileImage
    }
    
    var body: some View {
        VStack {
            HStack {
                profileImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding(profileImage == Image(systemName: "person.fill") ? 15 : 0)
                    .background(Color.gray.gradient)
                    .frame(width: 75, height: 75)
                    .clipShape(Circle())
                    .padding()
                    .shadow(radius: 2)
                Text("\(contact.givenName) \(contact.familyName)")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding(.leading, 50)
            
            ScrollView {
                if !contact.phoneNumbers.isEmpty {
                    ForEach(contact.phoneNumbers) { number in
                        CNLabeledView(value: number, type: .phoneNumber)
                    }
                    Divider().padding(.horizontal)
                }
                if !contact.emailAddresses.isEmpty {
                    ForEach(contact.emailAddresses) { email in
                        CNLabeledView(value: email, type: .email)
                    }
                    Divider().padding(.horizontal)
                }
                if let birthday = contact.birthday {
                    LabeledView(label: "birthday", value: dateFormatter.string(from: Calendar.current.date(from: birthday)!))
                    Divider()
                }
                if !contact.postalAddresses.isEmpty {
                    ForEach(contact.postalAddresses) { address in
                        CNLabeledView(value: address, type: .address)
                    }
                    Divider()
                }
            }
            
            Spacer()
        }
        .toolbar {
            Text("\(contact.givenName) \(contact.familyName)")
        }
        .onChange(of: contact) {
            profileImage = Image(systemName: "person.fill")
        #if canImport(AppKit)
            if let nsImage = NSImage(data: contact.imageData ?? Data()) {
                profileImage = Image(nsImage: nsImage)
            }
        #elseif canImport(UIKit)
            if let uiImage = UIImage(data: contact.imageData ?? Data()) {
                profileImage = Image(uiImage: uiImage)
            }
        #endif
        }
    }
}

extension CNLabeledValue: Identifiable {}

#Preview {
    ContactDetailView(contact: CNContact())
}
