//
//  CNLabelView.swift
//  Contact
//
//  Created by Thomas Patrick on 5/23/24.
//

import SwiftUI
import Contacts

enum ContactValueType {
    case phoneNumber
    case email
}

struct CNLabeledView<T>: View where T:NSCopying, T:NSSecureCoding {
    let value: CNLabeledValue<T>
    let type: ContactValueType
    
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
        if type == .phoneNumber, let phoneNumber = value as? CNLabeledValue<CNPhoneNumber> {
            if let label = phoneNumber.label, label.count > 0 {
                Text(CNLabeledValue<T>.localizedString(forLabel: label))
                    .cnLabel()
            } else {
                Text("phone")
                    .cnLabel()
            }
        } else if type == .email, let email = value as? CNLabeledValue<NSString> {
            if let label = email.label, label.count > 0 {
                Text(CNLabeledValue<T>.localizedString(forLabel: label))
                    .cnLabel()
            } else {
                Text("email")
                    .cnLabel()
            }
        } else {
            Text("Label Error")
                .cnLabel()
        }
    }
        
    @ViewBuilder
    func getLink() -> some View {
        if type == .phoneNumber, let phoneNumber = value as? CNLabeledValue<CNPhoneNumber> {
            if let URL = URL(string: "tel://\(phoneNumber.value.stringValue)") {
                Link(phoneNumber.value.stringValue, destination: URL)
            } else {
                Text(phoneNumber.value.stringValue)
            }
        } else if type == .email, let address = value as? CNLabeledValue<NSString> {
            if let URL = URL(string: "mailto://\(address.value)") {
                Link(String(address.value), destination: URL)
            } else {
                Text(String(address.value))
            }
        } else {
            Text("Value Error")
        }
    }
}

extension Text {
    func cnLabel() -> some View {
        self
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.trailing)
    }
}

#Preview {
    CNLabeledView<CNPhoneNumber>(value: CNLabeledValue<CNPhoneNumber>(), type: .phoneNumber)
}
