//
//  ContentView.swift
//  TestCheckAvailability
//
//  Created by Ting Chen on 11/18/25.
//

import ARKit
import ArcGIS
import CoreLocation
import SwiftUI

struct ContentView: View {
    /// A map with a light gray basemap.
    @State private var map = Map(basemap: .lightGray())
    /// A graphics overlay to show tapped locations.
    @State private var graphicsOverlay = GraphicsOverlay()
    /// A graphics overlay to show locations in Riverside County.
    @State private var riversideGraphicsOverlay = GraphicsOverlay()
    /// The tapped map point.
    @State private var mapPoint: Point?
    /// The availability status of geotracking at the tapped location.
    @State private var availability: GeoTrackingAvailability?
    /// The viewpoint near Esri Redlands to set on the map.
    @State private var viewpoint: Viewpoint? = Viewpoint(
        center: Point(x: -117.196, y: 34.057, spatialReference: .wgs84),
        scale: 1000
    )
    
    var body: some View {
        MapView(map: map, viewpoint: viewpoint, graphicsOverlays: [graphicsOverlay, riversideGraphicsOverlay])
            .onSingleTapGesture { _, mapPoint in
                Task {
                    await handleTap(point: mapPoint)
                }
            }
            .task {
                // Start checking availability.
                withAnimation {
                    availability = .checking
                }
                let graphics = await queryRiversideFishnetPoints()
                riversideGraphicsOverlay.addGraphics(graphics)
                let extent = GeometryEngine.combineExtents(of: graphics.map(\.geometry!))!.expanded(by: 1.3)
                viewpoint = Viewpoint(boundingGeometry: extent)
                // Done checking availability.
                availability = nil
            }
            .overlay(alignment: .top) {
                VStack {
                    if let mapPoint {
                        Text("lon: \(mapPoint.xDisplayString)")
                        Text("lat: \(mapPoint.yDisplayString)")
                    }
                    if let availability {
                        Text("Apple GeoTracking: \(availability.description)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(.regularMaterial, ignoresSafeAreaEdges: .horizontal)
            }
            .overlay {
                if availability == .checking {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(.rect(cornerRadius: 10))
                }
            }
    }
    
    /// Queries fishnet points in part of Riverside County, and checks
    /// geotracking availability for each location point.
    private func queryRiversideFishnetPoints() async -> [Graphic] {
        let featureLayer = FeatureLayer.fishnetPointsUSDACensus()
        try? await featureLayer.load()
        let featureTable = featureLayer.featureTable as! ServiceFeatureTable
        // Query all features in the feature table.
        let parameters = QueryParameters()
        parameters.whereClause = "1=1"
        parameters.returnsGeometry = true
        parameters.addOrderByField(OrderBy(fieldName: "FID", sortOrder: .ascending))
        
        // Query in two batches of 2000 features each.
        parameters.resultOffset = 0
        guard let result1 = try? await featureTable.queryFeatures(using: parameters, queryFeatureFields: .minimum) else {
            return []
        }
        parameters.resultOffset = 2000
        guard let result2 = try? await featureTable.queryFeatures(using: parameters, queryFeatureFields: .minimum) else {
            return []
        }
        
        // Check availability for each feature.
        var graphics: [Graphic] = []
        for feature in [result1.features(), result2.features()].joined() {
            guard let point = feature.geometry as? Point,
                  let coordinate = point.toCLLocationCoordinate2D()
            else {
                continue
            }
            // Check availability with ARKit.
            let isAvailable: Bool
            do {
                isAvailable = try await ARGeoTrackingConfiguration.checkAvailability(at: coordinate)
            } catch {
                isAvailable = false
            }
            // Update graphic color based on availability.
            let symbol = SimpleMarkerSymbol(style: .circle, color: isAvailable ? .green : .red, size: 4)
            let graphic = Graphic(geometry: GeometryEngine.project(point, into: .wgs84), symbol: symbol)
            graphics.append(graphic)
        }
        return graphics
    }
    
    /// Handles a tap on the map view.
    /// - Parameter point: The tap location.
    private func handleTap(point: Point) async {
        // Clear existing graphic if tapped again.
        if !graphicsOverlay.graphics.isEmpty {
            graphicsOverlay.removeAllGraphics()
            availability = nil
            mapPoint = nil
            return
        }
        
        // Convert to CLLocationCoordinate2D for ARKit.
        guard let coordinate = point.toCLLocationCoordinate2D() else {
            return
        }
        
        // Store the point.
        mapPoint = GeometryEngine.project(point, into: .wgs84)
        
        // Start checking availability.
        withAnimation {
            availability = .checking
        }
        
        // Create temporary orange point graphic.
        let tempSymbol = SimpleMarkerSymbol(style: .circle, color: .orange, size: 8)
        let graphic = Graphic(geometry: mapPoint, symbol: tempSymbol)
        graphicsOverlay.addGraphic(graphic)
        
        // Check availability with ARKit.
        do {
            let isAvailable = try await ARGeoTrackingConfiguration.checkAvailability(at: coordinate)
            availability = isAvailable ? .available : .unavailable
        } catch {
            availability = .unavailable
            print("Error checking geotracking availability: \(error.localizedDescription)")
        }
        // Update graphic color based on availability.
        let symbol = SimpleMarkerSymbol(style: .circle, color: availability == .available ? .green : .red, size: 16)
        graphic.symbol = symbol
    }
}

private extension ContentView {
    /// The availability status of geotracking.
    enum GeoTrackingAvailability {
        case available
        case unavailable
        case checking
        
        /// A description of the availability status.
        var description: String {
            switch self {
            case .available:
                return "Available"
            case .unavailable:
                return "Unavailable"
            case .checking:
                return "Checking..."
            }
        }
    }
}

private extension Point {
    /// String representation of the longitude with 6 decimal places.
    var xDisplayString: String {
        String(format: "%.6f", x)
    }
    
    /// String representation of the latitude with 6 decimal places.
    var yDisplayString: String {
        String(format: "%.6f", y)
    }
    
    /// Converts a point to `CLLocationCoordinate2D` in WGS84 spatial reference.
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D? {
        guard let projected = GeometryEngine.project(self, into: .wgs84) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: projected.y, longitude: projected.x)
    }
}

private extension ARGeoTrackingConfiguration {
    /// Determines if geotracking supports a particular location. See this [page](https://developer.apple.com/documentation/arkit/argeotrackingconfiguration/checkavailability(at:completionhandler:)).
    /// - Parameter coordinate: The GPS location that the framework checks for availability.
    /// - Returns: A Boolean that indicates whether geotracking is available at the current
    /// location or not. If not, an error will be thrown that indicates why geo tracking is
    /// not available at the current location.
    static func checkAvailability(at coordinate: CLLocationCoordinate2D) async throws -> Bool {
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Bool, Error>) in
            self.checkAvailability(at: coordinate) { isAvailable, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: isAvailable)
                }
            }
        }
    }
}

private extension FeatureLayer {
    /// A feature layer showing fishnet points from the USDA Census that covers
    /// part of Riverside County.
    static func fishnetPointsUSDACensus() -> FeatureLayer {
        FeatureLayer(
            item: PortalItem(
                portal: .arcGISOnline(connection: .anonymous),
                id: PortalItem.ID("e07d2e19761f45c9af4c115b9255dca9")!
            )
        )
    }
}

private extension Envelope {
    /// Expands the envelope by a given factor.
    /// - Parameter factor: The amount to expand the envelope by.
    /// - Returns: An envelope expanded by the specified factor.
    func expanded(by factor: Double) -> Envelope {
        let builder = EnvelopeBuilder(envelope: self)
        builder.expand(by: factor)
        return builder.toGeometry()
    }
}

private extension Basemap {
    /// A light gray basemap with local reference layer.
    static func lightGray() -> Basemap {
        Basemap(
            baseLayers: [ArcGISVectorTiledLayer(
                item: PortalItem(
                    portal: .arcGISOnline(connection: .anonymous),
                    id: PortalItem.ID("291da5eab3a0412593b66d384379f89f")!
                )
            )],
            referenceLayers: [ArcGISVectorTiledLayer(
                item: PortalItem(
                    portal: .arcGISOnline(connection: .anonymous),
                    id: PortalItem.ID("3ffec1551cd14606a286622c634b0bb4")!
                )
            )]
        )
    }
}
