//
//  BridgeManager.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 11/29/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation
import BoltsSwift
import Alamofire

class BridgeManager {
    
    enum BridgeDiscoveryError: Error {
        case valueNotFound
    }
    
    enum BridgeParsingError: Error {
        case typeCastFailed
        case failedToCreateBridge
    }
    
    static let shared = BridgeManager()
    
    static func getBridge(for configuration: Bridge.Info, user: WhitelistUser) -> Task<Bridge> {
        
        let bridgeSource = TaskCompletionSource<Bridge>()
        
        request("http://\(configuration.internalIpAddress)/api/\(user.name)/config")
            .responseJSON { (response) in
                
                guard let JSON = response.result.value as? [String: Any] else {
                    bridgeSource.set(error: BridgeParsingError.typeCastFailed)
                    return
                }
                
                guard let bridge = Bridge(JSON: JSON) else {
                    bridgeSource.set(error: BridgeParsingError.failedToCreateBridge)
                    return
                }
                
                bridgeSource.set(result: bridge)
                
        }
        
        return bridgeSource.task
    }
    
    static func findBridges() -> Task<[Bridge.Info]> {
        
        let taskCompletion = TaskCompletionSource<[Bridge.Info]>()
        
        let upnpEndpoint = "https://www.meethue.com/api/nupnp"
        
        SessionManager.default
            .request(upnpEndpoint, method: .get)
            .validate(statusCode: 200...299)
            .responseJSON { (response) in
                
                guard let bridges = response.result.value as? [[String: Any]] else {
                    
                    taskCompletion.set(error: BridgeDiscoveryError.valueNotFound)
                    
                    return
                }
                
                var configs: [Bridge.Info] = []
                
                for bridge in bridges {
                    
                    guard
                        let id = bridge["id"] as? String,
                        let ipAddress = bridge["internalipaddress"] as? String
                        else {
                            taskCompletion.set(error: BridgeDiscoveryError.valueNotFound)
                            return
                    }
                    
                    configs.append(
                        Bridge.Info(
                            id: id,
                            internalIpAddress: ipAddress
                        )
                    )
                }
                
                taskCompletion.set(result: configs)
                
        }
        
        return taskCompletion.task
    }
}
