//
//  Light.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/17/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation
import Mapper

protocol Multipliable {
    static func *(lhs: Self, rhs: Self) -> Self
}

extension Multipliable {
    var squared: Self {
        return self * self
    }
}

extension Double: Multipliable { }
extension CGFloat: Multipliable { }
extension Float: Multipliable { }
extension Int: Multipliable { }

extension CGPoint {
    func crossProduct(point: CGPoint) -> CGFloat {
        return x * point.y - y * point.x
    }
}

protocol Point {
    var x: CGFloat { get }
    var y: CGFloat { get }
}

extension Point {
    func distanceTo(point: Point) -> CGFloat {
        
        let dx = x - point.x
        let dy = y - point.y
        let distance = (dx.squared + dy.squared).squareRoot()
        
        return distance
    }
    
    func closestPoint(a: Point, b: Point) -> CGPoint {
        
        let ap = CGPoint(x: x - a.x, y: y - a.y)
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        
        let abSquared = ab.x.squared + ab.y.squared
        let apByAb = ap.x.squared + ap.y.squared
        
        var t = apByAb / abSquared
        
        if t < 0 {
            t = 0
        } else if t > 1 {
            t = 1
        }
        
        let closestPoint = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
        
        return closestPoint
    }
}

extension ColorspaceCoordinate: Point { }
extension CGPoint: Point { }

struct ColorPoints {
    let red: CGPoint
    let blue: CGPoint
    let green: CGPoint
    
    init(model: String) {
        
        let colorPoints: ColorPoints
        
        switch model {
        case "LCT001", "LCT002", "LCT003":
            colorPoints = ColorPoints(
                red: CGPoint(x: 0.675, y: 0.322),
                blue: CGPoint(x: 0.4091, y: 0.518),
                green: CGPoint(x: 0.167, y: 0.04)
            )
        case "LLC005", "LLC006", "LLC007", "LLC011", "LLC012", "LLC013", "LST001":
            colorPoints = ColorPoints(
                red: CGPoint(x: 0.704, y: 0.296),
                blue: CGPoint(x: 0.2151, y: 0.7106),
                green: CGPoint(x: 0.138, y: 0.08)
            )
        default:
            colorPoints = ColorPoints(
                red: CGPoint(x: 1, y: 0),
                blue: CGPoint(x: 0, y: 1),
                green: .zero
            )
        }
        
        self = colorPoints
    }
    
    init(red: CGPoint, blue: CGPoint, green: CGPoint) {
        self.red = red
        self.blue = blue
        self.green = green
    }
}

struct ColorspaceCoordinate: Convertible {
    let x: CGFloat
    let y: CGFloat
    
    static func fromMap(_ value: Any) throws -> ColorspaceCoordinate {
        guard let floatArray = value as? [CGFloat], floatArray.count == 2 else {
            throw MapperError.convertibleError(value: value, type: [CGFloat].self)
        }
        
        return ColorspaceCoordinate(x: floatArray[0], y: floatArray[1])
        
    }
    
    func isInLampsReach(for points: ColorPoints) -> Bool {
        
        let v1 = CGPoint(x: points.green.x - points.red.x, y: points.green.y - points.red.y)
        let v2 = CGPoint(x: points.blue.x - points.red.x, y: points.blue.y - points.red.y)
        
        let q = CGPoint(x: x - points.red.x, y: y - points.red.y)
        
        let s = q.crossProduct(point: v2) / v1.crossProduct(point: v2)
        let t = v1.crossProduct(point: q) / v1.crossProduct(point: v2)
        
        if s >= 0 && t >= 0 && s + t <= 1 {
            return true
        } else {
            return false
        }
    }
}

struct State: Mappable {
    
    let alert: String
    let brightness: Int
    let colorMode: String
    let colorTemperature: Int?
    let effect: String
    let hue: Int
    let isOn: Bool
    let isReachable: Bool
    let saturation: Int
    let colorspaceCoordinate: ColorspaceCoordinate
    
    init(map: Mapper) throws {
        try self.alert = map.from("alert")
        try self.brightness = map.from("bri")
        try self.colorMode = map.from("colormode")
        self.colorTemperature = map.optionalFrom("ct")
        try self.effect = map.from("effect")
        try self.hue = map.from("hue")
        try self.isOn = map.from("on")
        try self.isReachable = map.from("reachable")
        try self.saturation = map.from("sat")
        try self.colorspaceCoordinate = map.from("xy")
    }
}

struct Light: Mappable, Comparable {
    let id: String
    let manufacturerName: String
    let modelId: String
    let name: String
    let state: State
    let swversion: String
    let type: String
    let uniqueId: String
    
    var currentColor: UIColor {
        return Light.color(
            from: state.colorspaceCoordinate,
            brightness: state.brightness,
            model: modelId
        )
    }
    
    init(map: Mapper) throws {
        try self.id = map.from("id")
        try self.manufacturerName = map.from("manufacturername")
        try self.modelId = map.from("modelid")
        try self.name = map.from("name")
        try self.state = map.from("state")
        try self.swversion = map.from("swversion")
        try self.type = map.from("type")
        try self.uniqueId = map.from("uniqueid")
    }
    
    static func color(from xy: ColorspaceCoordinate, brightness: Int, model: String) -> UIColor {
        
        var xy = xy
        
        let colorPoints = ColorPoints(model: model)
        let inReachOfLamps = xy.isInLampsReach(for: colorPoints)
        
        if inReachOfLamps == false {
            
            let pab = xy.closestPoint(a: colorPoints.red, b: colorPoints.green)
            let pac = xy.closestPoint(a: colorPoints.blue, b: colorPoints.red)
            let pbc = xy.closestPoint(a: colorPoints.green, b: colorPoints.blue)
            
            let dab = xy.distanceTo(point: pab)
            let dac = xy.distanceTo(point: pac)
            let dbc = xy.distanceTo(point: pbc)
            
            var lowest = dab
            var closest = pab
            
            if dac < lowest {
                lowest = dac
                closest = pac
            }
            
            if dbc < lowest {
                lowest = dbc
                closest = pbc
            }
            
            xy = ColorspaceCoordinate(x: closest.x, y: closest.y)
        }
        
        let x = xy.x
        let y = xy.y
        let z = 1 - x - y
        
        let Y = CGFloat(brightness)
        let X = (Y / y) * x
        let Z = (Y / y) * z
        
        var r =  X * 1.656492 - Y * 0.354851 - Z * 0.255038
        var g = -X * 0.707196 + Y * 1.655397 + Z * 0.036152
        var b =  X * 0.051713 - Y * 0.121364 + Z * 1.011530
        
        if r > b && r > g && r > 1.0 {
            // red is too big
            g = g / r
            b = b / r
            r = 1.0
        } else if g > b && g > r && g > 1.0 {
            // green is too big
            r = r / g
            b = b / g
            g = 1.0
        } else if b > r && b > g && b > 1.0 {
            // blue is too big
            r = r / b
            g = g / b
            b = 1.0
        }
        
        r = r <= 0.0031308 ? 12.92 * r : (1.0 + 0.055) * pow(r, (1.0 / 2.4)) - 0.055
        g = g <= 0.0031308 ? 12.92 * g : (1.0 + 0.055) * pow(g, (1.0 / 2.4)) - 0.055
        b = b <= 0.0031308 ? 12.92 * b : (1.0 + 0.055) * pow(b, (1.0 / 2.4)) - 0.055
        
        if r > b && r > g {
            // red is biggest
            if r > 1.0 {
                g = g / r
                b = b / r
                r = 1.0
            }
        } else if g > b && g > r {
            // green is biggest
            if g > 1.0 {
                r = r / g
                b = b / g
                g = 1.0
            }
        } else if b > r && b > g {
            // blue is biggest
            if b > 1.0 {
                r = r / b
                g = g / b
                b = 1.0
            }
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    static func ==(lhs: Light, rhs: Light) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }
    
    static func <(lhs: Light, rhs: Light) -> Bool {
        return Int(lhs.id)! < Int(rhs.id)!
    }
}
