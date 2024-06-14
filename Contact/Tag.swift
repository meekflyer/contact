//
//  Item.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
//

import SwiftUI
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) let id: String
    var name: String
    private var color: String
    var parentID: String?
    var contactIDs: Set<String>

    init(name: String, color: Color.Resolved, parentID: String? = nil, contactIDs: Set<String> = []) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color.hexString
        self.parentID = parentID
        self.contactIDs = contactIDs
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
