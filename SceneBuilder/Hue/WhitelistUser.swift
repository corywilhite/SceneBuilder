//
//  WhitelistUser.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/17/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Pantry

struct WhitelistUser: Storable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    init?(warehouse: Warehouseable) {
        guard let name: String = warehouse.get("name") else { return nil }
        self.name = name
    }
    
    static func get() -> WhitelistUser? {
        return Pantry.unpack("whitelist-user")
    }
    
    static func store(user: WhitelistUser) {
        Pantry.pack(user, key: "whitelist-user")
    }
}
