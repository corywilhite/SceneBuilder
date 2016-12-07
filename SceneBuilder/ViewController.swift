//
//  ViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 11/29/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import UIKit
import SnapKit
import BoltsSwift
import Pantry

func printConfiguration(fromConfigurations configurations: [BridgeManager.Configuration]) -> BridgeManager.Configuration {
    
    print(configurations)
    
    return configurations.first!
}

func setConfiguration(configuration: BridgeManager.Configuration) -> BridgeManager.Configuration {
    BridgeManager.shared.selectBridge(configuration: configuration)
    return configuration
}

func createUser(withUsername username: String) -> WhitelistUser {
    return WhitelistUser(name: username)
}

func getUser() -> WhitelistUser? {
    return Pantry.unpack("whitelist-user")
}

func storeUser(_ user: WhitelistUser) {
    Pantry.pack(user, key: "whitelist-user")
}

struct WhitelistUser: Storable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    init?(warehouse: Warehouseable) {
        guard let name: String = warehouse.get("name") else { return nil }
        self.name = name
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = getUser() {
            print(user)
        } else {
            
            BridgeManager.findBridges()
                .continueOnSuccessWith(continuation: printConfiguration)
                .continueOnSuccessWith(continuation: setConfiguration)
                .continueOnSuccessWithTask(continuation: BridgePermissionManager.shared.startRequest)
                .continueOnSuccessWith(continuation: createUser)
                .continueOnSuccessWith(continuation: storeUser)
            
            
        }
        
        
        
    }
    
    
}

