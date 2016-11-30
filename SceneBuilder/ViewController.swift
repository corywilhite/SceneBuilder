//
//  ViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 11/29/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BridgeManager.shared.findBridges().continueWith { task in
            guard
                let configs = task.result
                else {
                    return
            }
            
            guard configs.count == 1 else { return }
            
            print(configs)
        }
        
    }

}

