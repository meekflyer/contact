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
    var contactIDs: [String]
    
    init(id: String, name: String, color: Color.Resolved, parentID: String? = nil, contactIDs: [String] = []) {
        self.id = id
        self.name = name
        self.color = color.hexString
        self.parentID = parentID
        self.contactIDs = contactIDs
    }
    
    func getColor() -> Color {
        return Color(hex: color)
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
