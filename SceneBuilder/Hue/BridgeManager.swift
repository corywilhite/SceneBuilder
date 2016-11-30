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
    static let shared = BridgeManager()
    
    struct Configuration {
        let id: String
        let internalIpAddress: String
    }
    
    var foundConfigs: [Configuration] = []
    
    enum BridgeDiscoveryError: Error {
        case valueNotFound
    }
    
    func findBridges() -> Task<[Configuration]> {
        
        let taskCompletion = TaskCompletionSource<[Configuration]>()
        
        let upnpEndpoint = "https://www.meethue.com/api/nupnp"
        
        SessionManager.default
            .request(upnpEndpoint, method: .get)
            .validate(statusCode: 200...299)
            .responseJSON { (response) in
                
                guard let bridges = response.result.value as? [[String: Any]] else {
                    
                    taskCompletion.set(error: BridgeDiscoveryError.valueNotFound)
                    
                    return
                }
                
                var configs: [Configuration] = []
                
                for bridge in bridges {
                    
                    guard
                        let id = bridge["id"] as? String,
                        let ipAddress = bridge["internalipaddress"] as? String
                        else {
                            taskCompletion.set(error: BridgeDiscoveryError.valueNotFound)
                            return
                    }
                    
                    configs.append(
                        Configuration(
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
