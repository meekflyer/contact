//
//  List.swift
//  Contact
//
//  Created by Thomas Patrick on 9/8/24.
//

import Foundation

struct ContactList: Identifiable {
    let id: String
    let name: String
    let contactIds: Set<UUID>
}
