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
import ExternalAccessory

// MARK: - UI and Actions

extension ViewController {
    enum DemoMode {
        case mapView, sceneView, arView
    }
    
    var currentView: DemoMode {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return .mapView
        case 1:
            return .sceneView
        case 2:
            return .arView
        default:
            fatalError("Unknown mode. Please check the segmented control binding.")
        }
    }
    
    func setupSceneViewObservation() {
        sceneViewObservation = sceneView.observe(\.isHidden, options: .initial) { sceneView, _ in
            DispatchQueue.main.async { [self] in
                if sceneView.isHidden {
                    // Reset displays.
                    currentLocationGraphicsOverlay.graphics.removeAllObjects()
                    satellitesGraphicsOverlay.graphics.removeAllObjects()
                } else {
                    if demoStarted {
                        // Add current location graphic to the overlay.
                        currentLocationGraphic.geometry = mapView.locationDisplay.location?.position
                        currentLocationGraphicsOverlay.graphics.add(currentLocationGraphic)
                        // Zoom out to see the satellites in the scene view.
                        zoomOut()
                    }
                }
            }
        }
    }
    
    func setupARViewObservation() {
        arViewObservation = arView.observe(\.isHidden, options: .initial) { arView, _ in
            DispatchQueue.main.async { [self] in
                if arView.isHidden {
                    if demoStarted {
                        arView.stopTracking()
                        arGraphicsOverlay.graphics.removeAllObjects()
                    }
                } else {
                    if demoStarted {
                        arView.startTracking(.continuous)
                    }
                }
            }
        }
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        switch currentView {
        case .mapView:
            mapView.isHidden = false
            sceneView.isHidden = true
            arView.isHidden = true
            zoomInBarButtonItem.isEnabled = false
            zoomOutBarButtonItem.isEnabled = false
        case .sceneView:
            mapView.isHidden = true
            sceneView.isHidden = false
            arView.isHidden = true
            zoomInBarButtonItem.isEnabled = true
            zoomOutBarButtonItem.isEnabled = true
        case .arView:
            mapView.isHidden = true
            sceneView.isHidden = true
            arView.isHidden = false
            zoomInBarButtonItem.isEnabled = false
            zoomOutBarButtonItem.isEnabled = false
        }
    }
    
    @IBAction func chooseDataSource(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose an NMEA data source.",
            message: nil,
            preferredStyle: .actionSheet
        )
        // Add real data source to the options.
        let realDataSourceAction = UIAlertAction(title: "Device", style: .default) { [self] _ in
            if let (accessory, protocolString) = firstSupportedAccessoryWithProtocol() {
                // Use the supported accessory directly if it's already connected.
                accessoryDidConnect(connectedAccessory: accessory, protocolString: protocolString)
            } else {
                // Show a picker to pair the device with a Bluetooth accessory.
                EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nil) { error in
                    if let error = error as? EABluetoothAccessoryPickerError,
                       error.code != .alreadyConnected {
                        switch error.code {
                        case .resultNotFound:
                            presentAlert(message: "The specified accessory could not be found, perhaps because it was turned off prior to connection.")
                        case .resultCancelled:
                            // Don't show error message when the picker is cancelled.
                            return
                        default:
                            presentAlert(message: "Selecting an accessory failed for an unknown reason.")
                        }
                    } else if let (accessory, protocolString) = firstSupportedAccessoryWithProtocol() {
                        // Proceed with supported and connected accessory, and
                        // ignore other accessories that aren't supported.
                        accessoryDidConnect(connectedAccessory: accessory, protocolString: protocolString)
                    }
                }
            }
        }
        alertController.addAction(realDataSourceAction)
        // Add mock data source to the options.
        let mockDataSourceAction = UIAlertAction(title: "Mock Data", style: .default) { [self] _ in
            nmeaLocationDataSource = AGSNMEALocationDataSource(receiverSpatialReference: .wgs84())
            nmeaLocationDataSource.locationChangeHandlerDelegate = self
            mockNMEADataSource.delegate = self
            mockNMEADataSource.start()
            arView.clippingDistance = 0
            start()
        }
        alertController.addAction(mockDataSourceAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    func start() {
        demoStarted = true
        // Set NMEA location data source for location display.
        mapView.locationDisplay.dataSource = nmeaLocationDataSource
        // Set buttons states.
        sourceBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
        // Start the data source and location display.
        mapView.locationDisplay.start()
        
        switch currentView {
        case .mapView:
            // Recenter the map and set pan mode.
            recenter()
        case .sceneView:
            // Add current location graphic to the overlay.
            currentLocationGraphic.geometry = mapView.locationDisplay.location?.position
            currentLocationGraphicsOverlay.graphics.add(currentLocationGraphic)
            // Zoom out to see the satellites in the scene view.
            zoomOut()
        case .arView:
            arView.startTracking(.continuous)
        }
    }
    
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .recenter
        recenterBarButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.recenterBarButtonItem.isEnabled = true
            }
            self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
        }
    }
    
    @IBAction func reset() {
        demoStarted = false
        // Reset buttons states.
        resetBarButtonItem.isEnabled = false
        sourceBarButtonItem.isEnabled = true
        // Reset and stop the location display.
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        // Stop the location display, which in turn stop the data source.
        mapView.locationDisplay.stop()
        // Pause the mock data generation.
        mockNMEADataSource.stop()
        // Disconnect from the mock data updates.
        mockNMEADataSource.delegate = nil
        // Reset NMEA location data source.
        nmeaLocationDataSource = nil
        
        switch currentView {
        case .mapView:
            return
        case .sceneView:
            // Reset displays.
            currentLocationGraphicsOverlay.graphics.removeAllObjects()
            satellitesGraphicsOverlay.graphics.removeAllObjects()
            zoomOut()
        case .arView:
            arView.stopTracking()
        }
    }
    
    @IBAction func zoomIn() {
        guard let currentLocationPoint = mapView.locationDisplay.location?.position else { return }
        sceneView.setViewpoint(AGSViewpoint(center: currentLocationPoint, scale: 1e4), duration: 3)
    }
    
    @IBAction func zoomOut() {
        guard let currentLocationPoint = mapView.locationDisplay.location?.position else { return }
        sceneView.setViewpoint(AGSViewpoint(center: currentLocationPoint, scale: 4e8), duration: 3)
    }
}

// MARK: - External Accessory Connection

extension ViewController {
    /// The Bluetooth accessory picker connected to a supported accessory.
    func accessoryDidConnect(connectedAccessory: EAAccessory, protocolString: String) {
        if let dataSource = AGSNMEALocationDataSource(eaAccessory: connectedAccessory, protocol: protocolString) {
            nmeaLocationDataSource = dataSource
            nmeaLocationDataSource.locationChangeHandlerDelegate = self
            arView.clippingDistance = 200
            start()
        } else {
            presentAlert(message: "NMEA location data source failed to initialize from the accessory!")
        }
    }
    
    /// Get the first connected and supported Bluetooth accessory with its
    /// protocol string.
    /// - Returns: A tuple of the accessory and its protocol,
    ///            or nil if no supported accessory exists.
    func firstSupportedAccessoryWithProtocol() -> (EAAccessory, String)? {
        for accessory in EAAccessoryManager.shared().connectedAccessories {
            // The protocol string to establish the EASession.
            guard let protocolString = accessory.protocolStrings.first(where: { supportedProtocolStrings.contains($0) }) else {
                // Skip the accessories with protocol not for NMEA data transfer.
                continue
            }
            // Only return the first connected and supported accessory.
            return (accessory, protocolString)
        }
        return nil
    }
}

// MARK: - Coordinate System Conversion

extension ViewController {
    /// Convert degree value to radian.
    /// - Parameter degrees: Degree value.
    /// - Returns: Radian value.
    func radians(from degrees: Double) -> Double {
        degrees * .pi / 180
    }
    
    /// Convert radian value to degree.
    /// - Parameter radians: Radian value.
    /// - Returns: Degree value.
    func degrees(from radians: Double) -> Double {
        radians * 180 / .pi
    }
    
    /// Convert spherical coordinates to Cartesian.
    /// - Note: Please read the [wiki page](https://en.wikipedia.org/wiki/Spherical_coordinate_system#Cartesian_coordinates).
    /// - Parameters:
    ///   - r: The radius
    ///   - theta: Inclination theta.
    ///   - phi: Azimuth phi.
    /// - Returns: A `simd_double3` vector in Cartesian coordinates.
    func sphericalToCartesian(r: Double, theta: Double, phi: Double) -> simd_double3 {
        let x = r * sin(theta) * cos(phi)
        let y = r * sin(theta) * sin(phi)
        let z = r * cos(theta)
        return simd_double3(x, y, z)
    }
    
    /// Convert Cartesian coordinates to spherical
    /// - Parameter vector: A `simd_double3` vector in Cartesian coordinates.
    /// - Returns: A tuple of (r, theta, phi) in radians.
    func cartesianToSpherical(vector: simd_double3) -> (r: Double, theta: Double, phi: Double) {
        let (x, y, z) = (vector.x, vector.y, vector.z)
        let r = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
        let theta = acos(z / r)
        let phi = atan2(y, x)
        return (r, theta, phi)
    }
}

// MARK: - `AGSGraphic` Helpers

extension ViewController {
    func makeSatellitesGraphics(satellites: [(info: AGSNMEASatelliteInfo, point: AGSPoint)]) -> [AGSGraphic] {
        let inUseSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .systemRed, size: 10)
        let spareSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .systemGray, size: 5)
        let satellitesGraphics: [AGSGraphic] = satellites.map { info, point in
            // lon \(String(format: "%.2f", point.x))\nlat \(String(format: "%.2f", point.y))
            let textSymbol = AGSTextSymbol(
                text: """
                \(info.system.abbreviation) ID \(info.satelliteID)
                a: \(info.azimuth) e: \(info.elevation)
                """,
                color: .white,
                size: 15,
                horizontalAlignment: .center,
                verticalAlignment: .bottom
            )
            let symbol = info.inUse ? inUseSymbol : spareSymbol
            let compositeSymbol = AGSCompositeSymbol(symbols: [symbol, textSymbol])
            return AGSGraphic(geometry: point, symbol: compositeSymbol)
        }
        return satellitesGraphics
    }
    
    func makeLeadersGraphics(satellitePoints: [AGSPoint], groundLocationPoint: AGSPoint) -> [AGSGraphic] {
        let leadersSymbol = AGSSimpleLineSymbol(style: .dash, color: .systemRed, width: 0.3)
        let leadersGraphics: [AGSGraphic] = satellitePoints.map { point in
            // Add a leader line between each satellite and the ground location.
            let leaderLine = AGSPolyline(points: [point, groundLocationPoint])
            return AGSGraphic(geometry: leaderLine, symbol: leadersSymbol)
        }
        return leadersGraphics
    }
    
    /// A not-in-use method to create satellite graphics for AR view.
    ///
    /// - Note: There are limitations for the furthest visible distance of graphics
    /// in an AR view. which makes it not possible to draw the satellites
    /// in their real positions. One workaround is to position the satellites
    /// at a fraction along the POV line. However, that would introduce
    /// the parallax effect, which makes it visually confusing
    /// in an AR experience. Therefore, the satellites are not displayed here.
    func makeARSatellitesGraphics(satellitePoints: [AGSPoint], groundLocationPoint: AGSPoint) -> [AGSGraphic] {
        let leadersLines: [AGSPolyline] = satellitePoints.map { satellitePoint in
            // The leader line between the ground location and each satellite.
            AGSPolyline(points: [groundLocationPoint, satellitePoint])
        }
        let symbol = AGSSimpleMarkerSceneSymbol(style: .diamond, color: .orange, height: 50, width: 50, depth: 50, anchorPosition: .center)
        let satellitesGraphics: [AGSGraphic] = leadersLines.map { line in
            // The distance is represented in percentage. Possible values range
            // from 0.0001% to around 1%, given the orbit distance ~20200 km.
            let closerPoint = AGSGeometryEngine.point(along: line, distance: 1e-3)
            return AGSGraphic(geometry: closerPoint, symbol: symbol)
        }
        return satellitesGraphics
    }
    
    func makeARLeadersGraphics(satellites: [(info: AGSNMEASatelliteInfo, point: AGSPoint)], groundLocationPoint: AGSPoint) -> [AGSGraphic] {
        let redStrokeSymbolLayer = AGSSolidStrokeSymbolLayer(
            width: 0.5,
            color: .systemRed,
            geometricEffects: [],
            lineStyle3D: .tube
        )
        let grayStrokeSymbolLayer = AGSSolidStrokeSymbolLayer(
            width: 3,
            color: .systemGray,
            geometricEffects: [],
            lineStyle3D: .strip
        )
        let inUseSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [redStrokeSymbolLayer])
        let spareSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [grayStrokeSymbolLayer])
        let leadersGraphics: [AGSGraphic] = satellites.map { info, satellitePoint in
            // Add a leader line between each satellite and the ground location.
            let leaderLine = AGSPolyline(points: [groundLocationPoint, satellitePoint])
            let symbol = info.inUse ? inUseSymbol : spareSymbol
            return AGSGraphic(geometry: leaderLine, symbol: symbol)
        }
        return leadersGraphics
    }
}

// MARK: - Labels for Global Navigation Satellite Systems

private extension AGSNMEAGNSSSystem {
    var label: String {
        switch self {
        case .GPS:
            return "The Global Positioning System"
        case .GLONASS:
            return "The Russian Global Navigation Satellite System"
        case .galileo:
            return "The European Union Global Navigation Satellite System"
        case .BDS:
            return "The BeiDou Navigation Satellite System"
        case .QZSS:
            return "The Quasi-Zenith Satellite System"
        case .navIC:
            return "The Navigation Indian Constellation"
        default:
            return "Unknown GNSS type"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .GPS:
            return "GPS"
        case .GLONASS:
            return "GLONASS"
        case .galileo:
            return "Galileo"
        case .BDS:
            return "BeiDou"
        case .QZSS:
            return "QZSS"
        case .navIC:
            return "navIC"
        default:
            return "NA"
        }
    }
}

// MARK: - Alert

extension UIViewController {
    /// Shows an alert with the given title, message, and an OK button.
    func presentAlert(title: String? = "Error", message: String? = nil) {
        let okAction = UIAlertAction(title: "OK", style: .default)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert, actions: [okAction])
        present(alertController, animated: true)
    }
}

private extension UIAlertController {
    /// Initializes the alert controller with the given parameters, adding the
    /// actions successively and setting the first action as preferred.
    convenience init(title: String? = nil, message: String? = nil, preferredStyle: UIAlertController.Style = .alert, actions: [UIAlertAction] = []) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        for action in actions {
            addAction(action)
        }
        preferredAction = actions.first
    }
}
