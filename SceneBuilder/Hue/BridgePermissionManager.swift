//
//  BridgePermissionManager.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/7/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation
import BoltsSwift
import Alamofire

class BridgePermissionManager {
    static let shared = BridgePermissionManager()
    
    func startRequest(with configuration: BridgeManager.Configuration) -> Task<String>{
        
        let usernameSource = TaskCompletionSource<String>()
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            
            self.startRequest(with: configuration, timer: timer)
                .continueOnSuccessWith(continuation: { usernameSource.set(result: $0) })
            
        }
        
        return usernameSource.task
        
    }
    
    var tries = 0
    
    enum BridgePermissionError: Error {
        case unexpectedResponse
        case timeout
    }
    
    func startRequest(with configuration: BridgeManager.Configuration, timer: Timer) -> Task<String> {
        
        let usernameSource = TaskCompletionSource<String>()
        
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
                        usernameSource.set(error: BridgePermissionError.unexpectedResponse)
                        return
                }
                
                if let successDictionary = responseDictionary["success"] as? [String: Any],
                    let username = successDictionary["username"] as? String {
                    timer.invalidate()
                    usernameSource.set(result: username)
                    return
                    
                } else if let errorDictionary = responseDictionary["error"] as? [String: Any],
                    let errorDescription = errorDictionary["description"] as? String {
                    
                    print(errorDescription)
                    
                    if self.tries == 6 {
                        print("invalidating timer")
                        timer.invalidate()
                        
                        usernameSource.set(error: BridgePermissionError.timeout)
                    }
                    
                } else {
                    print("didnt receive expected response type")
                }
                
                self.tries += 1
        }
        
        return usernameSource.task
        
    }
}
