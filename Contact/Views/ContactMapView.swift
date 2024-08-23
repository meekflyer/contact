//
//  ContactMapView.swift
//  Contact
//
//  Created by Thomas Patrick on 8/21/24.
//

import Contacts
import MapKit
import SwiftUI

struct ContactMapItem: Hashable {
    let title: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let address: CNLabeledValue<CNPostalAddress>

    init?(name: String, address: CNLabeledValue<CNPostalAddress>) async {
        if let coordinate = await address.value.getCoordinate() {
            var label: String? = nil
            if let addressLabel = address.label {
                label = CNLabeledValue<CNPostalAddress>.localizedString(forLabel: addressLabel)
            }
            self.title = name + " " + (label ?? "")
            self.coordinate = coordinate
            self.imageName = switch label {
            case "home": "house.fill"
            case "work": "building.2.fill"
            case "school": "graduationcap.fill"
            default: "figure"
            }
            self.address = address
        } else {
            return nil
        }
    }

    static func == (lhs: ContactMapItem, rhs: ContactMapItem) -> Bool {
        return lhs.title == rhs.title &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.imageName == rhs.imageName &&
        lhs.address.identifier == rhs.address.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(address.identifier)
    }
}

extension CNPostalAddress {
    func getCoordinate() async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        return try? await geocoder.geocodePostalAddress(self).first?.location?.coordinate
    }
}

struct ContactMapView: View {
    let contacts: Binding<[CNContact]>
    @State private var contactMapItems = [ContactMapItem]()
    @State private var loading = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map() {
                UserAnnotation()
                ForEach(contactMapItems, id: \.self) { contactMapItem in
                    Marker(contactMapItem.title,
                           systemImage: contactMapItem.imageName,
                           coordinate: contactMapItem.coordinate)
                }
            }
            
            if loading {
                ProgressView()
                    .frame(width: 10)
                    .padding()
            }
        }
        .task {
            await updateMapItems()
        }
        .onChange(of: contacts.wrappedValue) { _, _ in
            Task {
                await updateMapItems()
            }
        }
    }

    func updateMapItems() async {
        await MainActor.run {
            loading = true
        }
        var items = [ContactMapItem]()
        for contact in contacts.wrappedValue {
            for address in contact.postalAddresses {
                if let item = await ContactMapItem(name: contact.givenName,
                                                   address: address) {
                    items.append(item)
                }
            }
        }
        let updateItems = items
        await MainActor.run {
            withAnimation {
                contactMapItems = updateItems
                loading = false
            }
        }
    }
}

#Preview {
    ContactMapView(contacts: .constant([CNContact()]))
}
