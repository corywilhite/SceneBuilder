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

func printConfiguration(fromConfigurations configurations: [BridgeManager.Configuration]) -> BridgeManager.Configuration {
    
    print(configurations)
    
    return configurations.first!
}

func setConfiguration(configuration: BridgeManager.Configuration) -> BridgeManager.Configuration {
    BridgeManager.shared.selectBridge(configuration: configuration)
    return configuration
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BridgeManager
            .findBridges()
            .continueOnSuccessWith(continuation: printConfiguration)
            .continueOnSuccessWith(continuation: setConfiguration)
            .continueOnSuccessWith(continuation: BridgeManager.shared.startBridgeRegistration)
        
    }

}

