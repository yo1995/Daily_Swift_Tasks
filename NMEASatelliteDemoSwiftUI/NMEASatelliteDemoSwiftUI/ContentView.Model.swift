import ArcGIS
import Combine
import ExternalAccessory
import simd

extension ContentView {
    @MainActor
    class Model: ObservableObject {
        /// The map for the map view.
        let map = Map(basemapStyle: .arcGISTopographic)
        /// The location display used in the map view.
        let locationDisplay = LocationDisplay()
        /// The scene for the scene view.
        let scene: Scene = {
            let scene = Scene(basemapStyle: .arcGISOceans)
            let surface = Surface()
            surface.addElevationSource(ArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!))
            scene.baseSurface = surface
            return scene
        }()
        /// The graphics overlay to draw satellites and their leaders.
        let satellitesGraphicsOverlay: GraphicsOverlay = {
            let overlay = GraphicsOverlay()
            overlay.sceneProperties.surfacePlacement = .absolute
            return overlay
        }()
        /// The graphic overlay to draw current location in a scene, to mimic the location display in the map.
        let currentLocationGraphicsOverlay: GraphicsOverlay = {
            let overlay = GraphicsOverlay(graphics: [Graphic(symbol: SimpleMarkerSymbol(style: .circle, color: .orange, size: 15))])
            return overlay
        }()
        /// An NMEA location data source, to parse NMEA data.
        private(set) var nmeaLocationDataSource: NMEALocationDataSource!
        /// A mock data reader to read NMEA sentences from a local file, and generate mock NMEA data every fixed amount of time.
        let sentenceReader = FileNMEASentenceReader(
            url: Bundle.main.url(forResource: "Redlands", withExtension: "nmea")!,
            interval: 0.66
        )
        /// The protocols used in this sample to get NMEA sentences.
        /// They are also specified in the `Info.plist` to allow the app to
        /// communicate with external accessory hardware.
        private let supportedProtocolStrings: Set = [
            "com.bad-elf.gps",
            "com.emlid.nmea",
            "com.eos-gnss.positioningsource",
            "com.geneq.sxbluegpssource"
        ]
        /// An orange circle showing the current location in a scene.
        var currentLocationGraphic: Graphic {
            currentLocationGraphicsOverlay.graphics.first!
        }
        /// The most recent location reported by the location data source.
        var currentPosition: Point?
        
        // MARK: Instance methods
        
        /// Calculates a satellite's position from its elevation and azimuth angles.
        /// - Parameters:
        ///   - deviceLocation: The location of the device that receives satellite info.
        ///   - elevation: The elevation angle.
        ///   - azimuth: The azimuth angle.
        ///   - satelliteAltitude: The satellite's altitude above ground level.
        ///   - earthRadius: The earth's radius.
        /// - Returns: A point representing the position of the satellite.
        func satellitePosition(
            deviceLocation: Point,
            elevation: Measurement<UnitAngle>,
            azimuth: Measurement<UnitAngle>,
            satelliteAltitude: Measurement<UnitLength> = .init(value: 20200, unit: .kilometers),
            earthRadius: Measurement<UnitLength> = .init(value: 6371, unit: .kilometers)
        ) -> Point {
            // Degree to radian conversions.
            let longitude = Measurement<UnitAngle>(value: deviceLocation.x, unit: .degrees).converted(to: .radians).value
            let latitude = Measurement<UnitAngle>(value: deviceLocation.y, unit: .degrees).converted(to: .radians).value
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
            return Point(
                x: resultLongitude,
                y: resultLatitude,
                z: satelliteAltitude.converted(to: .meters).value,
                spatialReference: .wgs84
            )
        }
        
        /// Starts the location data source and awaits location and satellite updates.
        /// - Parameter nmeaLocationDataSource: An optional data source created from a MFi external accessory.
        func start(nmeaLocationDataSource: NMEALocationDataSource?) async throws {
            if let nmeaLocationDataSource {
                // Use a real device as data source.
                self.nmeaLocationDataSource = nmeaLocationDataSource
            } else {
                // Use the mocked data as data source.
                self.nmeaLocationDataSource = NMEALocationDataSource(receiverSpatialReference: .wgs84)
                // Start the mock data generation.
                sentenceReader.start()
            }
            // Set NMEA location data source for location display.
            locationDisplay.dataSource = self.nmeaLocationDataSource
            // Set the autopan mode to `.recenter`
            locationDisplay.autoPanMode = .recenter
            // Start the data source.
            try await locationDisplay.dataSource.start()
        }
        
        /// Resets the graphics, stops the data source and mock data generation.
        func reset() async {
            satellitesGraphicsOverlay.removeAllGraphics()
            // Reset NMEA location data source.
            nmeaLocationDataSource = nil
            locationDisplay.autoPanMode = .off
            // Stop the location display, which in turn stop the data source.
            await locationDisplay.dataSource.stop()
            // Pause the mock data generation.
            sentenceReader.stop()
        }
    }
}

// MARK: - Helper methods

extension ContentView.Model {
    /// Converts spherical coordinates to Cartesian.
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
    
    /// Converts Cartesian coordinates to spherical
    /// - Parameter vector: A `simd_double3` vector in Cartesian coordinates.
    /// - Returns: A tuple of (r, theta, phi) in radians.
    func cartesianToSpherical(vector: simd_double3) -> (r: Double, theta: Double, phi: Double) {
        let (x, y, z) = (vector.x, vector.y, vector.z)
        let r = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
        let theta = acos(z / r)
        let phi = atan2(y, x)
        return (r, theta, phi)
    }
    
    /// Makes satellite graphics.
    /// - Parameter satellites: An array of satellite information.
    /// - Returns: An array of graphics.
    func makeSatellitesGraphics(satellites: [(info: NMEASatelliteInfo, point: Point)]) -> [Graphic] {
        let inUseSymbol = SimpleMarkerSymbol(style: .circle, color: .systemRed, size: 10)
        let spareSymbol = SimpleMarkerSymbol(style: .circle, color: .systemGray, size: 5)
        let satellitesGraphics: [Graphic] = satellites.map { info, point in
            let satelliteText = """
                \(info.system!.abbreviation) ID \(info.id)
                a: \(info.azimuth) e: \(info.elevation)
                """
            let latLonText = "lat \(String(format: "%.2f", point.y))\nlon \(String(format: "%.2f", point.x))"
            let textSymbol = TextSymbol(
                text: satelliteText,
                color: .white,
                size: 15,
                horizontalAlignment: .center,
                verticalAlignment: .bottom
            )
            let symbol = info.isInUse ? inUseSymbol : spareSymbol
            let compositeSymbol = CompositeSymbol(symbols: [symbol, textSymbol])
            return Graphic(
                geometry: point,
                attributes: ["Info": satelliteText, "LatLon": latLonText],
                symbol: compositeSymbol
            )
        }
        return satellitesGraphics
    }
    
    /// Makes leader graphics for satellites.
    /// - Parameters:
    ///   - satellitePoints: The positions of satellites.
    ///   - locationPoint: The device location.
    /// - Returns: An array of leader graphics.
    func makeLeadersGraphics(satellitePoints: [Point], locationPoint: Point) -> [Graphic] {
        let leadersSymbol = SimpleLineSymbol(style: .dash, color: .systemRed, width: 0.3)
        let leadersGraphics: [Graphic] = satellitePoints.compactMap { point in
            // Add a leader line between each satellite and the ground location.
            let leaderLine = Polyline(points: [point, locationPoint])
            return Graphic(geometry: leaderLine, symbol: leadersSymbol)
        }
        return leadersGraphics
    }
    
    /// Updates the graphics with current location in the scene view.
    /// - Parameter satelliteInfo: An array of satellite information.
    func updateGraphicsInScene(with satelliteInfo: [NMEASatelliteInfo]) {
        // 1. Update the current location graphic.
        guard let p = currentPosition else { return }
        // Get rid of the `vcsWkid` property of the original location.
        let currentLocationPoint = Point(x: p.x, y: p.y, z: p.z, m: p.m, spatialReference: .wgs84)
        currentLocationGraphic.geometry = currentLocationPoint
        
        // 2. Update the satellite graphics.
        let satellitePoints = satelliteInfo.map { satellite in
            satellitePosition(
                deviceLocation: currentLocationPoint,
                elevation: satellite.elevation,
                azimuth: satellite.azimuth
            )
        }
        satellitesGraphicsOverlay.removeAllGraphics()
        // Add circles to represent the location of satellites.
        satellitesGraphicsOverlay.addGraphics(makeSatellitesGraphics(satellites: Array(zip(satelliteInfo, satellitePoints))))
        // Add leader lines between current location and satellites.
        satellitesGraphicsOverlay.addGraphics(makeLeadersGraphics(satellitePoints: satellitePoints, locationPoint: currentLocationPoint))
    }
    
    /// Gets the first connected and supported Bluetooth accessory with its protocol string.
    /// - Returns: A tuple of the accessory and its protocol, or `nil` if no supported accessory exists.
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

// MARK: - Global Navigation Satellite Systems

private extension NMEAGNSSSystem {
    /// The full name of a satellite system.
    var label: String {
        switch self {
        case .gps:
            return "The Global Positioning System"
        case .glonass:
            return "The Russian Global Navigation Satellite System"
        case .galileo:
            return "The European Union Global Navigation Satellite System"
        case .bds:
            return "The BeiDou Navigation Satellite System"
        case .qzss:
            return "The Quasi-Zenith Satellite System"
        case .navIC:
            return "The Navigation Indian Constellation"
        default:
            return "Unknown GNSS type"
        }
    }
    /// The abbreviation of a satellite system.
    var abbreviation: String {
        switch self {
        case .gps:
            return "GPS"
        case .glonass:
            return "GLONASS"
        case .galileo:
            return "Galileo"
        case .bds:
            return "BeiDou"
        case .qzss:
            return "QZSS"
        case .navIC:
            return "navIC"
        default:
            return "NA"
        }
    }
}
