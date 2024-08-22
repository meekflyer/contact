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
    case address
}

struct LabeledView: View {
    let label: AnyView
    let value: AnyView
    
    init(label: AnyView, value: AnyView) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: String) {
        self.label = AnyView(Text(label).cnLabel())
        self.value = AnyView(Text(value))
    }
    
    var body: some View {
        HStack(spacing: 5) {
            VStack {
                HStack {
                    Spacer()
                    label
                }
                Spacer()
            }
            .frame(width: 150)
            VStack(alignment: .leading) {
                value
                    .textSelection(.enabled)
                Spacer()
            }
            Spacer()
        }
    }
}

struct CNLabeledView<T>: View where T:NSCopying, T:NSSecureCoding {
    let value: CNLabeledValue<T>
    let type: ContactValueType
    
    var body: some View {
        LabeledView(label: AnyView(getLabel()), value: AnyView(getLink()))
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
        } else if type == .address, let address = value as? CNLabeledValue<CNPostalAddress> {
            if let label = address.label { Text(CNLabeledValue<T>.localizedString(forLabel: label))
                    .cnLabel()
            } else {
                Text("address")
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
            if let URL = URL(string: "tel:\(phoneNumber.value.stringValue)") {
                Link(phoneNumber.value.stringValue, destination: URL)
            } else {
                Text(phoneNumber.value.stringValue)
            }
        } else if type == .email, let email = value as? CNLabeledValue<NSString> {
            if let URL = URL(string: "mailto://\(email.value)") {
                Link(String(email.value), destination: URL)
            } else {
                Text(String(email.value))
            }
        } else if type == .address, let address = value as? CNLabeledValue<CNPostalAddress> {
            if let URL = URL(string: "http://maps.apple.com/?address=\(CNPostalAddressFormatter().string(from: address.value))") {
                Link(destination: URL) {
                    Text(CNPostalAddressFormatter().string(from: address.value))
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(CNPostalAddressFormatter().string(from: address.value))
                    .multilineTextAlignment(.leading)
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
