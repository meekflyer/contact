//
//  List.swift
//  Contact
//
//  Created by Thomas Patrick on 9/8/24.
//

import Foundation

struct ContactList: ContactGroup {
    let id: String
    var name: String
    var contactIDs: Set<String>

    var uuid: UUID {
        // Group ids are UUIDs with ":ABGroup" appended to the end
        let idString = String(id.dropLast(8))
        return UUID(uuidString: idString) ?? UUID()
    }

    func getContactIds(tags: [Tag]? = nil) -> Set<String> {
        contactIDs
    }
}
