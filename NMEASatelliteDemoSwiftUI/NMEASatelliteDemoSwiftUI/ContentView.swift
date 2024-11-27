import ArcGIS
import ArcGISToolkit
import SwiftUI

struct ContentView: View {
    /// The data model used for the demo.
    @StateObject private var model = Model()
    /// An Enum indicating which kind of view is selected.
    @State private var selectedViewOption = SatelliteViewOption.mapView
    /// A Boolean indicating whether the menu to select NMEA source is disabled.
    @State private var sourceMenuIsDisabled = false
    /// A Boolean indicating whether the "Reset" button is disabled.
    @State private var resetButtonIsDisabled = true
    /// A Boolean indicating whether the "Zoom In" button is tapped for the scene view.
    @State private var zoomInButtonTapped = false
    /// A Boolean indicating whether the "Zoom Out" button is tapped for the scene view.
    @State private var zoomOutButtonTapped = false
    /// The error shown in the error alert.
    @State private var error: Error?
    /// The placement of the satellite callout on the scene.
    @State private var calloutPlacement: CalloutPlacement?
    
    var body: some View {
        VStack {
            switch selectedViewOption {
            case .mapView:
                MapView(map: model.map)
                    .locationDisplay(model.locationDisplay)
            case .sceneView:
                SceneViewReader { proxy in
                    SceneView(
                        scene: model.scene,
                        graphicsOverlays: [
                            model.currentLocationGraphicsOverlay,
                            model.satellitesGraphicsOverlay
                        ]
                    )
                    .task(id: zoomInButtonTapped) {
                        defer { zoomInButtonTapped = false }
                        guard zoomInButtonTapped, let currentLocationPoint = model.currentPosition else { return }
                        await proxy.setViewpoint(Viewpoint(center: currentLocationPoint, scale: 1e4), duration: 3)
                    }
                    .task(id: zoomOutButtonTapped) {
                        defer { zoomOutButtonTapped = false }
                        guard zoomOutButtonTapped, let currentLocationPoint = model.currentPosition else { return }
                        // Earth radius in meters.
                        let earthRadius = 6378137.0
                        let maxZoomHeight = 9 * earthRadius
                        let newPoint = GeometryEngine.makeGeometry(from: currentLocationPoint, z: maxZoomHeight)
                        await proxy.setViewpointCamera(Camera(location: newPoint, heading: 0, pitch: 0, roll: 0), duration: 3)
                    }
                    .task {
                        if (try? await model.scene.load()) != nil {
                            // Mimic "Zoom Out" button tapped to set the viewpoint afar after the scene finishes loading.
                            zoomOutButtonTapped = true
                        }
                    }
                }
            case .arSceneView:
                WorldScaleSceneView { proxy in
                    SceneView(
                        scene: model.scene,
                        graphicsOverlays: [
                            model.currentLocationGraphicsOverlay,
                            model.satellitesGraphicsOverlay
                        ]
                    )
                    .callout(placement: $calloutPlacement) { placement in
                        let attributes = (placement.geoElement as! Graphic).attributes
                        VStack(alignment: .leading) {
                            Text(attributes["Info"] as! String)
                            Text(attributes["LatLon"] as! String)
                        }
                    }
                    .onSingleTapGesture { screenPoint, _ in
                        Task {
                            do {
                                let identifyResult = try await proxy.identify(
                                    on: model.satellitesGraphicsOverlay,
                                    screenPoint: screenPoint,
                                    tolerance: 12
                                )
                                if let graphic = identifyResult.graphics.first,
                                   let graphicPoint = graphic.geometry as? Point {
                                    calloutPlacement = .geoElement(graphic, tapLocation: graphicPoint)
                                }
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
            }
        }
        .task(id: model.sentenceReader.isStarted) {
            guard model.sentenceReader.isStarted, let dataSource = model.nmeaLocationDataSource else { return }
            // Push the mock data to the NMEA location data source.
            // This simulates the case where the NMEA messages coming from a hardware need to be
            // manually pushed to the data source.
            for await data in model.sentenceReader.messages {
                dataSource.pushData(data)
            }
        }
        .task(id: model.nmeaLocationDataSource?.status) {
            guard let dataSource = model.nmeaLocationDataSource, dataSource.status == .started else { return }
            for await mapLocation in model.nmeaLocationDataSource.locations {
                model.currentPosition = mapLocation.position
            }
        }
        .task(id: model.nmeaLocationDataSource?.status) {
            guard let dataSource = model.nmeaLocationDataSource, dataSource.status == .started else { return }
            for await satellitesInfo in dataSource.satellites {
                if selectedViewOption == .sceneView || selectedViewOption == .arSceneView {
                    // Only updates the graphics when the scene view is visible.
                    model.updateGraphicsInScene(with: satellitesInfo)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Picker("Views", selection: $selectedViewOption) {
                    Text(SatelliteViewOption.mapView.label)
                        .tag(SatelliteViewOption.mapView)
                    Text(SatelliteViewOption.sceneView.label)
                        .tag(SatelliteViewOption.sceneView)
                    Text(SatelliteViewOption.arSceneView.label)
                        .tag(SatelliteViewOption.arSceneView)
                }
                Spacer()
                Menu("Sources") {
                    Button("Device") {
                        guard let (accessory, protocolString) = model.firstSupportedAccessoryWithProtocol() else {
                            error = MyError(message: "No supported MFi NMEA device connected.")
                            return
                        }
                        let dataSource = NMEALocationDataSource(accessory: accessory, protocol: protocolString)
                        Task {
                            do {
                                try await model.start(nmeaLocationDataSource: dataSource)
                                sourceMenuIsDisabled = true
                                resetButtonIsDisabled = false
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    Button("Mock Data") {
                        Task {
                            do {
                                try await model.start(nmeaLocationDataSource: nil)
                                sourceMenuIsDisabled = true
                                resetButtonIsDisabled = false
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
                .disabled(sourceMenuIsDisabled)
                Spacer()
                Menu("Actions") {
                    Section("All") {
                        Button("Reset") {
                            sourceMenuIsDisabled = false
                            resetButtonIsDisabled = true
                            Task {
                                await model.reset()
                            }
                        }
                        .disabled(resetButtonIsDisabled)
                    }
                    Section("Map View") {
                        Button("Recenter") {
                            if model.locationDisplay.autoPanMode != .recenter {
                                model.locationDisplay.autoPanMode = .recenter
                            }
                        }
                    }
                    .disabled(selectedViewOption != .mapView)
                    Section("Scene View") {
                        Button("Zoom In") {
                            zoomInButtonTapped = true
                        }
                        Button("Zoom Out") {
                            zoomOutButtonTapped = true
                        }
                    }
                    .disabled(selectedViewOption != .sceneView)
                    Section("AR Scene View") {
                        // More actions to be added for AR.
                    }
                }
            }
        }
        .alert(
            "Error",
            isPresented: error == nil ? .constant(false) : .constant(true),
            presenting: error
        ) { _ in
            Button("OK") { error = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

private extension ContentView {
    enum SatelliteViewOption: Hashable {
        case mapView
        case sceneView
        case arSceneView
        
        var label: String {
            switch self {
            case .mapView:
                "Map View"
            case .sceneView:
                "Scene View"
            case .arSceneView:
                "AR Scene View"
            }
        }
    }
}

private struct MyError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

#Preview {
    ContentView()
}
