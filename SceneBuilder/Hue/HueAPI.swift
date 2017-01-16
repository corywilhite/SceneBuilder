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
                
                let lightsWithIds: [[String: Any]] = JSON.flatMap {
                    var json = $0.value as? [String: Any]
                    json?["id"] = $0.key
                    return json
                }
                
                let lights: [Light] = lightsWithIds.flatMap {
                    let dict = NSDictionary(dictionary: $0)
                    let light = Light.from(dict)
                    return light
                }.sorted()
                
                dump(lights)
                
                lightSource.set(result: lights)
        }
        
        return lightSource.task
    }
    
    func turnOn(light: Light) -> Task<Void> {
        return update(light: light, with: ["on": true])
    }
    
    func turnOff(light: Light) -> Task<Void> {
        return update(light: light, with: ["on": false])
    }
    
    @discardableResult
    func changeBrightness(for light: Light, to newBrightness: Int) -> Task<Void> {
        return update(light: light, with: ["bri": newBrightness])
    }
    
    func update(light: Light, with state: [String: Any]) -> Task<Void> {
        
        let updateSource = TaskCompletionSource<Void>()
        
        let url = baseURL() + "/lights/\(light.id)/state"
        
        request(
            url,
            method: .put,
            parameters: state, 
            encoding: JSONEncoding.default
        )
            .validate(statusCode: 200...299)
            .responseJSON { (response) in
                
                updateSource.set(result: ())
                print("success")
        }
        
        return updateSource.task
    }
    
    func getState(light: Light) -> Task<Light> {
        
        let lightSource = TaskCompletionSource<Light>()
        
        let url = baseURL() + "/lights/\(light.id)"
        
        request(url).validate(statusCode: 200...299).responseJSON { (response) in
            
            guard var JSON = response.result.value as? [String: Any] else {
                lightSource.set(error: ParsingError.jsonSerializationFailed)
                return
            }
            
            JSON["id"] = light.id
            
            let dictionary = NSDictionary(dictionary: JSON)
            
            guard let light = Light.from(dictionary) else {
                lightSource.set(error: ParsingError.jsonSerializationFailed)
                return
            }
            
            lightSource.set(result: light)
            
        }
        
        return lightSource.task
    }
}
