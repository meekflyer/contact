//
//  Item.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
//

import SwiftUI
import SwiftData

protocol ContactGroup: Equatable, Identifiable {
    var id: String { get }
    var uuid: UUID { get }
    var name: String { get set }
    var contactIDs: Set<String> { get set }

    func getContactIds(tags: [Tag]?) -> Set<String>
}

struct Token: ContactGroup {
    private var _group: any ContactGroup

    init(_ group: some ContactGroup) {
        _group = group
    }

    var id: String { _group.id }
    var uuid: UUID { _group.uuid }
    var name: String {
        get { _group.name }
        set { _group.name = newValue }
    }
    var contactIDs: Set<String> {
        get { _group.contactIDs }
        set { _group.contactIDs = newValue }
    }

    func getContactIds(tags: [Tag]?) -> Set<String> {
        _group.getContactIds(tags: tags)
    }

    static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.id == rhs.id &&
        lhs.uuid == rhs.uuid &&
        lhs.name == rhs.name &&
        lhs.contactIDs == rhs.contactIDs
    }
}

@Model
final class Tag: ContactGroup {
    @Attribute(.unique) let id: String
    var name: String
    private var color: String
    var parentID: String?
    var contactIDs: Set<String>
    var uuid: UUID {
        UUID(uuidString: id) ?? UUID()
    }

    init(name: String, color: Color.Resolved, parentID: String? = nil, contactIDs: Set<String> = []) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color.hexString
        self.parentID = parentID
        self.contactIDs = contactIDs
    }

    func getContactIds(tags: [Tag]?) -> Set<String> {
        guard let tags else { return Set<String>() }
        return getContactIDsWithDescendents(from: tags)
    }
}

extension Tag {
    func getColor() -> Color {
        return Color(hex: color)
    }

    func isDescendent(of tag: Tag, in tags: [Tag]) -> Bool {
        if self == tag {
            return true
        }
        let children = tags.children(of: tag)
        if children.isEmpty {
            return false
        } else if children.contains(self) {
            return true
        } else {
            for child in children {
                return self.isDescendent(of: child, in: tags)
            }
        }

        return false
    }

    func getContactIDsWithDescendents(from tags: [Tag]) -> Set<String> {
        var allContactIDs = contactIDs
        tags.children(of: self).forEach { child in
            allContactIDs.formUnion(child.getContactIDsWithDescendents(from: tags))
        }
        return allContactIDs
    }
}

extension [Tag] {
    func children(of tag: Tag) -> [Tag] {
        return self.filter({ $0.parentID == tag.id })
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

extension Color.Resolved {
    var hexString: String {
        let red = Int(self.red * 255)
        let green = Int(self.green * 255)
        let blue = Int(self.blue * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
