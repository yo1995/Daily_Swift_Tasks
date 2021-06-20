// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class ViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .topographic())
            mapView.setViewpointScale(1e8)
        }
    }
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.isHidden = true
            sceneView.spaceEffect = .stars
            sceneView.scene = {
                let scene = AGSScene(basemap: .topographic())
                let surface = AGSSurface()
                let elevationSource = AGSArcGISTiledElevationSource(
                    url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
                )
                surface.elevationSources.append(elevationSource)
                scene.baseSurface = surface
                return scene
            }()
            sceneView.graphicsOverlays.addObjects(from: [satellitesGraphicsOverlay, currentLocationGraphicsOverlay])
        }
    }
    
    /// The button to choose a data source and start the demo.
    @IBOutlet var sourceBarButtonItem: UIBarButtonItem!
    /// The button to reset pan mode to "recenter".
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    /// The button to reset the demo.
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    /// The button to zoom in the scene view.
    @IBOutlet var zoomInBarButtonItem: UIBarButtonItem!
    /// The button to zoom out the scene view.
    @IBOutlet var zoomOutBarButtonItem: UIBarButtonItem!
    
    // MARK: Instance properties
    
    /// The graphics overlay to draw satellites and their leaders.
    let satellitesGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.sceneProperties?.surfacePlacement = .absolute
        return overlay
    }()
    /// The graphic overlay to draw current location in a scene, to mimic the location display in the map.
    let currentLocationGraphicsOverlay = AGSGraphicsOverlay()
    /// An orange circle showing the current location in a scene.
    let currentLocationGraphic = AGSGraphic(
        geometry: nil,
        symbol: AGSSimpleMarkerSymbol(style: .circle, color: .orange, size: 15)
    )
    
    /// An NMEA location data source, to parse NMEA data.
    var nmeaLocationDataSource: AGSNMEALocationDataSource!
    /// A mock data source to read NMEA sentences from a local file, and generate
    /// mock NMEA data every fixed amount of time.
    let mockNMEADataSource = SimulatedNMEADataSource(
        nmeaSourceFile: Bundle.main.url(forResource: "Redlands", withExtension: "nmea")!
    )
    
    /// The protocols specified in the `Info.plist` that the app uses to
    /// communicate with external accessory hardware.
    let supportedProtocolStrings: Set<String> = Bundle.main
        .object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols")
        .flatMap { $0 as? [String] }
        .map(Set.init) ?? []
    
    // MARK: Instance methods
    
    func satellitePosition(
        deviceLocation: AGSPoint,
        elevation: Measurement<UnitAngle>,
        azimuth: Measurement<UnitAngle>,
        satelliteAltitude: Measurement<UnitLength> = .init(value: 20200, unit: .kilometers),
        earthRadius: Measurement<UnitLength> =  .init(value: 6371, unit: .kilometers)
    ) -> AGSPoint {
        // Degree to radian conversions.
        let longitude = Measurement(value: deviceLocation.x, unit: UnitAngle.degrees).converted(to: .radians).value
        let latitude = Measurement(value: deviceLocation.y, unit: UnitAngle.degrees).converted(to: .radians).value
        let elevation = elevation.converted(to: .radians).value
        let azimuth = azimuth.converted(to: .radians).value
        // 1. Basic trigonometry
        let r1 = earthRadius.value
        let r2 = r1 + satelliteAltitude.value
        let elevationAngle = elevation + .pi / 2
        let inscribedAngle = asin(r1 * sin(elevationAngle) / r2)  // Law of Sines
        let centralAngle = .pi - elevationAngle - inscribedAngle  // Internal angles sum = pi
        
        // 2. Magical quaternions
        let latLonAxis = simd_normalize(sphericalToCartesian(r: r1, theta: .pi / 2 - latitude, phi: longitude))
        // Find the vector between device location and North point (z axis)
        var thirdAxis = simd_normalize(simd_double3(0, 0, 1 / latLonAxis.z) - latLonAxis)
        // Rotate to the azimuth angle
        let quaternionAzimuth = simd_quatd(
            angle: 1.5 * .pi - azimuth,
            axis: latLonAxis
        )
        thirdAxis = quaternionAzimuth.act(thirdAxis)
        // Rotate the lat-lon vector to elevation angle, with the rotated third axis
        let quaternionElevation = simd_quatd(
            angle: -centralAngle,
            axis: thirdAxis
        )
        let resultVector = quaternionElevation.act(latLonAxis)
        
        // 3. Make result
        let result = cartesianToSpherical(vector: resultVector)
        let resultLatitude = Measurement(value: .pi / 2 - result.theta, unit: UnitAngle.radians).converted(to: .degrees).value
        let resultLongitude = Measurement(value: result.phi, unit: UnitAngle.radians).converted(to: .degrees).value
        return AGSPoint(x: resultLongitude, y: resultLatitude, z: satelliteAltitude.converted(to: .meters).value, spatialReference: .wgs84())
    }
    
    /// Update the graphics with current location in the scene.
    func updateGraphicsInScene(with satelliteInfo: [AGSNMEASatelliteInfo]) {
        // 1. update the current location.
        guard let p = mapView.locationDisplay.location?.position else { return }
        // Get rid of the `vcsWkid` property of the original location.
        let currentLocationPoint = AGSPointMake3D(p.x, p.y, p.z, p.m, .wgs84())
        currentLocationGraphic.geometry = currentLocationPoint
        // 2. update the satellite graphics.
        let satellitePoints = satelliteInfo.map { satellite in
            satellitePosition(
                deviceLocation: currentLocationPoint,
                elevation: Measurement(value: satellite.elevation, unit: UnitAngle.degrees),
                azimuth: Measurement(value: satellite.azimuth, unit: UnitAngle.degrees)
            )
        }
        satellitesGraphicsOverlay.graphics.removeAllObjects()
        // Add circles to represent the location of satellites.
        satellitesGraphicsOverlay.graphics.addObjects(from: makeSatellitesGraphics(satellites: Array(zip(satelliteInfo, satellitePoints))))
        // Add leader lines between current location and satellites.
        satellitesGraphicsOverlay.graphics.addObjects(from: makeLeadersGraphics(satellitePoints: satellitePoints, locationPoint: currentLocationPoint))
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceBarButtonItem.isEnabled = true
    }
}

// MARK: - AGSNMEALocationDataSourceDelegate

extension ViewController: AGSNMEALocationDataSourceDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Un-comment to get additional attributes from the location.
        // guard let nmeaLocation = location as? AGSNMEALocation else { return }
    }
    
    func nmeaLocationDataSource(_ NMEALocationDataSource: AGSNMEALocationDataSource, satellitesDidChange satellites: [AGSNMEASatelliteInfo]) {
        // When new satellite info is received from the device, we should
        // update the graphics in a visible scene.
        if !sceneView.isHidden {
            updateGraphicsInScene(with: satellites)
        }
    }
}

// MARK: - SimulatedNMEADataSourceDelegate

extension ViewController: SimulatedNMEADataSourceDelegate {
    func dataSource(_ dataSource: SimulatedNMEADataSource, didUpdate nmeaData: Data) {
        // Push mock data into the data source.
        // Note: You can also get real-time NMEA sentences from a GNSS surveyor.
        nmeaLocationDataSource.push(nmeaData)
    }
}
