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
    
    struct Configuration {
        let id: String
        let internalIpAddress: String
    }
    
    enum BridgeDiscoveryError: Error {
        case valueNotFound
    }
    
    static let shared = BridgeManager()
    
    private var currentConfiguration: Configuration?
    
    func selectBridge(configuration: Configuration) {
        currentConfiguration = configuration
    }
    
    func startBridgeRegistration(for configuration: Configuration) {
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            
            self.requestBridgePermssion(for: configuration, timer: timer)
            
        }
        
    }
    
    var tries = 0
    
    func requestBridgePermssion(for configuration: Configuration, timer: Timer) {
        
        let url = "http://\(configuration.internalIpAddress)/api"
        
        request(
            url,
            method: .post,
            parameters: ["devicetype": "com.corywilhite.SceneBuilder"],
            encoding: JSONEncoding.default,
            headers: nil
            )
            .responseJSON { (response) in
                print(response)
                
                guard let rawResponse = response.result.value as? [[String: Any]],
                    let responseDictionary = rawResponse.first else {
                        print("unexpected response")
                        timer.invalidate()
                        return
                }
                
                if let successDictionary = responseDictionary["success"] as? [String: Any],
                    let username = successDictionary["username"] as? String {
                    
                    print("Retrieved Username: \(username)")
                    timer.invalidate()
                    return
                    
                } else if let errorDictionary = responseDictionary["error"] as? [String: Any],
                    let errorDescription = errorDictionary["description"] as? String {
                    
                    print(errorDescription)
                    
                    if self.tries == 6 {
                        print("invalidating timer")
                        timer.invalidate()
                    }
                    
                } else {
                    print("didnt receive expected response type")
                }
                
                self.tries += 1
        }
        
    }
    
    static func findBridges() -> Task<[Configuration]> {
        
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
