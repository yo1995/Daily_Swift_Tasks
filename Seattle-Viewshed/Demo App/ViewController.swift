import UIKit
import ArcGIS

class ViewController: UIViewController {
    /// The 3D scene view for the demo.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeSeattleScene()
            sceneView.analysisOverlays.add(analysisOverlay)
            sceneView.setViewpointCamera(AGSCamera(location: startLocation, heading: 45, pitch: 60, roll: 0))
            sceneView.touchDelegate = self
            sceneView.atmosphereEffect = .realistic
            sceneView.sunLighting = .lightAndShadows
            
            let thatNightInSeattle = Calendar.current.date(byAdding: DateComponents(hour: 10), to: Calendar.current.startOfDay(for: Date()))!
            sceneView.sunTime = thatNightInSeattle  // Date()
        }
    }
    
    /// 3D buildings for the City of Seattle.
    let seattleBuildingsLayer = AGSArcGISSceneLayer(
        item: AGSPortalItem(
            portal: .arcGISOnline(withLoginRequired: false),
            itemID: "894d7f3b120d40cb9ef2b2a656e9bc5b"
        )
    )
    
    /// The viewshed analysis overlay.
    let analysisOverlay = AGSAnalysisOverlay()
    
    /// A point above the Space Needle.
    let startLocation = AGSPoint(x: -122.354, y: 47.617, z: 450, spatialReference: .wgs84())
    
    /// The current observation point.
    var currentMapPoint: AGSPoint?
    
    /// A Seattle 3D building scene.
    func makeSeattleScene() -> AGSScene {
        // Warning: this is the deprecated basemap constructor.
        // Get an API key to use the new constructor in production app.
        let scene = AGSScene(basemapType: .lightGrayCanvasVector)
        // Create a surface set it as the base surface of the scene.
        let surface = AGSSurface()
        // The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        surface.elevationSources.append(AGSArcGISTiledElevationSource(url: worldElevationServiceURL))
        scene.baseSurface = surface
        // Add the 3D buildings layer.
        scene.operationalLayers.add(seattleBuildingsLayer)
        return scene
    }
    
    /// Create a viewshed at a location.
    func createViewshed(at location: AGSPoint) -> AGSLocationViewshed {
        let unionLakeCenter = AGSPoint(x: -122.3402889, y: 47.6366135, spatialReference: .wgs84())
        let camera = sceneView.currentViewpointCamera()
        let viewshed = AGSLocationViewshed(
            location: location,
            heading: camera.move(toLocation: unionLakeCenter).heading,
            pitch: 90,
            horizontalAngle: 60,
            verticalAngle: 180,
            minDistance: 500,
            maxDistance: 3000
        )
        return viewshed
    }
    
    /// Change the viewpoint between 2D and 3D.
    @IBAction func setViewpointCamera(_ sender: UIBarButtonItem) {
        let currentCamera = sceneView.currentViewpointCamera()
        if currentCamera.pitch < 45 {
            seattleBuildingsLayer.isVisible = true
            sceneView.setViewpointCamera(AGSCamera(location: startLocation, heading: 45, pitch: 60, roll: 0), completion: nil)
        } else {
            seattleBuildingsLayer.isVisible = false
            let point = currentMapPoint ?? startLocation
            sceneView.setViewpointCamera(AGSCamera(location: point, heading: 0, pitch: 0, roll: 0))
            sceneView.setViewpoint(AGSViewpoint(center: point, scale: 1e4), duration: 1)
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension ViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        seattleBuildingsLayer.clearSelection()
        analysisOverlay.analyses.removeAllObjects()
        currentMapPoint = mapPoint
        // Identify the building feature in the scene.
        sceneView.identifyLayer(
            seattleBuildingsLayer,
            screenPoint: screenPoint,
            tolerance: 10,
            returnPopupsOnly: false
        ) { [unowned self] result in
            if let feature = result.geoElements.first as? AGSFeature {
                seattleBuildingsLayer.select(feature)
                let heightInFeet = Measurement(value: feature.attributes["BP99_APEX"] as! Double, unit: UnitLength.feet)
                let height = heightInFeet.converted(to: UnitLength.meters).value
                let point = AGSPoint(x: mapPoint.x, y: mapPoint.y, z: height, spatialReference: .wgs84())
                // Update the observer location from which the viewshed is calculated.
                analysisOverlay.analyses.add(createViewshed(at: point))
            } else if let error = result.error {
                print(error.localizedDescription)
            }
        }
    }
}
