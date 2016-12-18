//
//  Light.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/17/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation

struct Light {
    
    struct State {
        
        struct XY {
            let x: String
            let y: String
            
            init?(xy: [String]) {
                guard xy.count == 2 else {
                    return nil
                }
                
                x = xy[0]
                y = xy[1]
            }
        }
        
        let alert: String
        let brightness: Int
        let colorMode: String
        let ct: Int
        let effect: String
        let hue: Int
        let on: Bool
        let reachable: Bool
        let saturation: Int
        let xy: XY
        
        init?(JSON: [String: Any]) {
            guard let alert = JSON["alert"] as? String else { return nil }
            self.alert = alert
            
            guard let brightness = JSON["bri"] as? Int else { return nil }
            self.brightness = brightness
            
            guard let colorMode = JSON["colormode"] as? String else { return nil }
            self.colorMode = colorMode
            
            guard let ct = JSON["ct"] as? Int else { return nil }
            self.ct = ct
            
            guard let effect = JSON["effect"] as? String else { return nil }
            self.effect = effect
            
            guard let hue = JSON["hue"] as? Int else { return nil }
            self.hue = hue
            
            guard let on = JSON["on"] as? Bool else { return nil }
            self.on = on
            
            guard let reachable = JSON["reachable"] as? Bool else { return nil }
            self.reachable = reachable
            
            guard let saturation = JSON["sat"] as? Int else { return nil }
            self.saturation = saturation
            
            guard let rawXY = JSON["xy"] as? [String], let xy = XY(xy: rawXY)  else { return nil }
            self.xy = xy
        }
    }
    
    
    let id: String
    let manufacturerName: String
    let modelId: String
    let name: String
    let state: State
    let swversion: String
    let type: String
    let uniqueId: String
    
    init?(id: String, JSON: [String: Any]) {
        self.id = id
        
        guard let manufacturerName = JSON["manufacturername"] as? String else { return nil }
        self.manufacturerName = manufacturerName
        
        guard let modelId = JSON["modelid"] as? String else { return nil }
        self.modelId = modelId
        
        guard let name = JSON["name"] as? String else { return nil }
        self.name = name
        
        guard let rawState = JSON["state"] as? [String: Any], let state = State(JSON: rawState) else { return nil }
        self.state = state
        
        guard let swversion = JSON["swversion"] as? String else { return nil }
        self.swversion = swversion
        
        guard let type = JSON["type"] as? String else { return nil }
        self.type = type
        
        guard let uniqueId = JSON["uniqueid"] as? String else { return nil }
        self.uniqueId = uniqueId
    }
}
