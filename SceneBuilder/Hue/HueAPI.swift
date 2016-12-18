//
//  HueAPI.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/17/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import BoltsSwift
import Alamofire

struct HueAPI {
    let configuration: Bridge.Info
    let user: WhitelistUser
    
    func baseURL() -> String {
        return "http://\(configuration.internalIpAddress)/api/\(user.name)"
    }
    
    enum ParsingError: Error {
        case jsonSerializationFailed
    }
    
    func getLights() -> Task<[Light]> {
        
        let lightSource = TaskCompletionSource<[Light]>()
        
        let url = baseURL() + "/lights"
        
        request(url, method: .get)
            .validate(statusCode: 200...299)
            .responseJSON { (response) in
                
                guard response.result.isSuccess else {
                    response.result.error.map { lightSource.set(error: $0) }
                    return
                }
                
                guard let JSON = response.result.value as? [String: Any] else {
                    lightSource.set(error: ParsingError.jsonSerializationFailed)
                    return
                }
                
                let lights = JSON.flatMap { Light(id: $0.key, JSON: $0.value as? [String: Any] ?? [:]) }
                
                dump(lights)
                
                lightSource.set(result: lights)
        }
        
        return lightSource.task
    }
}
