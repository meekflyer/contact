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
    @State var profileImage = Image(systemName: "person.fill")
    
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
                    ForEach(contact.phoneNumbers, id: \.self) { number in
                        CNLabeledView(value: number)
                    }
                    Divider()
                        .padding(.horizontal)
                }
                if !contact.emailAddresses.isEmpty {
                    ForEach(contact.emailAddresses, id: \.self) { address in
                        EmptyView()
//                        CNLabeledView(value: address)
                    }
                    Divider()
                        .padding(.horizontal)
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
            if let uiImage = UIImage(data: contact.imageData) {
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
