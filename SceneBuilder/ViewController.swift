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

func getBridge(user: WhitelistUser) -> (Bridge.Info) -> Task<Bridge> {
    return {
        BridgeManager.getBridge(for: $0, user: user)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var startScanButton: UIButton! {
        didSet {
            startScanButton.addTarget(
                self,
                action: #selector(startScanButtonPressed(sender:)),
                for: .touchUpInside
            )
        }
    }
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var connectedStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getBridgeIfNeeded()
    }
    
    func getBridgeIfNeeded() {
        
        if let user = WhitelistUser.get() {
            
            setConnected(true)
            
            dump(user)
            
            let lightsController = LightsViewController(user: user)
            
            present(lightsController, animated: true, completion: nil)
            
            
        } else {
            setConnected(false)
        }
        
    }
    
    func getBridgeConfiguration(user: WhitelistUser) {
        
        BridgeManager
            .findBridges()
            .continueOnSuccessWith(continuation: { $0.first! })
            .continueOnSuccessWithTask(continuation: getBridge(user: user))
            .continueOnSuccessWith(continuation: { (bridge) -> Void in
                dump(bridge)
            })
        
    }
    
    func createUserProcedure() {
        
        BridgeManager.findBridges()
            .continueOnSuccessWith(continuation: { $0.first! })
            .continueOnSuccessWithTask(continuation: BridgePermissionManager.shared.startRequest)
            .continueOnSuccessWith(continuation: WhitelistUser.init(name:))
            .continueOnSuccessWith(continuation: WhitelistUser.store)
            .continueOnSuccessWith(continuation: { self.setConnected(true) })
        
    }
    
    func setConnected(_ connected: Bool) {
        connectedStatusLabel.textColor = connected ? .green :.red
        connectedStatusLabel.text = "\(connected)"
        
    }
    
    func startScanButtonPressed(sender: UIButton) {
        createUserProcedure()
    }
    
}

