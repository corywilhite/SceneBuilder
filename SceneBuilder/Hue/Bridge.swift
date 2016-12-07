//
//  Bridge.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/7/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation

struct Bridge {
    let name: String
    let apiVersion: String
    let softwareVersion: String
    let proxyAddress: String
    let proxyPort: String
    let macAddress: String
    let netMask: String
    let gateway: String
    let usesDHCP: Bool
    let providesPortalServices: Bool
    let currentTimeUTC: String
    let localTime: String
    let zigbeeChannel: String
    let modelId: String
    let bridgeId: String
    let isFactoryNew: Bool
    
    init?(JSON: [String: Any]) {
        guard let name = JSON["name"] as? String else { return nil }
        self.name = name
        guard let apiVersion = JSON["apiversion"] as? String else { return nil }
        self.apiVersion = apiVersion
        guard let softwareVersion = JSON["swversion"] as? String else { return nil }
        self.softwareVersion = softwareVersion
        guard let proxyAddress = JSON["proxyaddress"] as? String else { return nil }
        self.proxyAddress = proxyAddress
        guard let proxyPort = JSON["proxyport"] as? String else { return nil }
        self.proxyPort = proxyPort
        guard let macAddress = JSON["macaddress"] as? String else { return nil }
        self.macAddress = macAddress
        guard let netMask = JSON["netmask"] as? String else { return nil }
        self.netMask = netMask
        guard let gateway = JSON["gateway"] as? String else { return nil }
        self.gateway = gateway
        guard let usesDHCP = JSON["dhcp"] as? Bool else { return nil }
        self.usesDHCP = usesDHCP
        guard let providesPortalServices = JSON["portalservices"] as? Bool else { return nil }
        self.providesPortalServices = providesPortalServices
        guard let currentTimeUTC = JSON["UTC"] as? String else { return nil }
        self.currentTimeUTC = currentTimeUTC
        guard let localTime = JSON["localtime"] as? String else { return nil }
        self.localTime = localTime
        guard let zigbeeChannel = JSON["zigbeechannel"] as? String else { return nil }
        self.zigbeeChannel = zigbeeChannel
        guard let modelId = JSON["modelid"] as? String else { return nil }
        self.modelId = modelId
        guard let bridgeId = JSON["bridgeid"] as? String else { return nil }
        self.bridgeId = bridgeId
        guard let isFactoryNew = JSON["factorynew"] as? Bool else { return nil }
        self.isFactoryNew = isFactoryNew
    }
}
