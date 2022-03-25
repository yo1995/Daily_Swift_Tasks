//
//  CodableLocation.swift
//  Demo App
//
//  Created by Ting Chen on 2/23/22.
//

import Foundation
import ArcGIS

struct CodableLocation: Codable {
    let course: Double
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let position: CodablePoint
    let timestamp: Date
    let velocity: Double
    let additionalSourceProperties: [String: String]
    
    init?(location: AGSLocation) {
        guard let locationPoint = location.position else { return nil }
        course = location.course
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        position = CodablePoint(point: locationPoint)
        timestamp = location.timestamp
        velocity = location.velocity
        additionalSourceProperties = Self.parseAdditionalSourceProperties(properties: location.additionalSourceProperties)
    }
    
    static func parseAdditionalSourceProperties(properties: [AGSLocationSourcePropertyKey: Any]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: properties.compactMap { (k: AGSLocationSourcePropertyKey, v: Any) in
            let key = k.rawValue
            let value: String?
            switch k {
            case .floor, .transmitterCount, .satelliteCount:
                value = String(v as! Int)
            case .positionSource:
                value = v as? String
            default:
                value = nil
            }
            if let value = value {
                return (key, value)
            } else {
                return nil
            }
        })
    }
}

struct CodablePoint: Codable {
    // The position along x-axis.
    let x: Double
    // The position along y-axis.
    let y: Double
    // The position along z-axis.
    let z: Double
    // The WKText (well-known text) of the spatial reference.
    let spatialReference: String?
    
    init(point: AGSPoint) {
        x = point.x
        y = point.y
        z = point.z
        spatialReference = point.spatialReference?.wkText
    }
}
