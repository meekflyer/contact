//
//  CNLabelView.swift
//  Contact
//
//  Created by Thomas Patrick on 5/23/24.
//

import SwiftUI
import Contacts

struct CNLabeledView<T>: View where T:NSCopying, T:NSSecureCoding {
    let value: CNLabeledValue<T>
    
    var body: some View {
        HStack(spacing: 5) {
            VStack {
                HStack {
                    Spacer()
                    getLabel()
                }
                Spacer()
            }
            .frame(width: 150)
            VStack(alignment: .leading) {
                getLink()
                Spacer()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func getLabel() -> some View {
        if let phoneNumber = value as? CNLabeledValue<CNPhoneNumber> {
            if let label = value.label, label.count > 0 {
                Text(CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("phone")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        } else {
            Text("Label Error")
        }
    }
    
    @ViewBuilder
    func getLink() -> some View {
        if let phoneNumber = value as? CNLabeledValue<CNPhoneNumber> {
            if let URL = URL(string: "tel://number.value.stringValue") {
                Link(phoneNumber.value.stringValue, destination: URL)
            } else {
                Text(phoneNumber.value.stringValue)
            }
        } else if let address = value as? CNLabeledValue<NSString> {
            Text(String(address.value))
        } else {
            Text("Value Error")
        }
    }
}

#Preview {
    CNLabeledView<CNPhoneNumber>(value: CNLabeledValue<CNPhoneNumber>())
}
