import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = AGSScene(basemap: .imagery())
            sceneView.graphicsOverlays.addObjects(from: [linesGraphicsOverlay, dotsGraphicsOverlay])
        }
    }
    
    let linesGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleLineSymbol(style: .solid, color: .cyan, width: 3)
        )
        return overlay
    }()
    
    let dotsGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleMarkerSymbol(style: .circle, color: .orange, size: 8)
        )
        return overlay
    }()
    
    /// Create division points on a geodesic line between 2 points on the Earth's surface.
    /// - Parameters:
    ///   - point1: The first point.
    ///   - point2: The second point.
    ///   - n: N equally divided segments between 2 points, or N-1 division points.
    /// - Returns: An array of the division points.
    func makeDivisionPoints(point1: AGSPoint, point2: AGSPoint, n: Int) -> [AGSPoint] {
        guard n > 1 else { return [] }
        let distanceUnit: AGSLinearUnit = .kilometers()
        let azimuthUnit: AGSAngularUnit = .degrees()
        let curveType: AGSGeodeticCurveType = .geodesic
        let distanceResult = AGSGeometryEngine.geodeticDistanceBetweenPoint1(point1, point2: point2, distanceUnit: distanceUnit, azimuthUnit: azimuthUnit, curveType: curveType)!
        return (1..<n).flatMap { AGSGeometryEngine.geodeticMove([point1], distance: distanceResult.distance * Double($0) / Double(n), distanceUnit: distanceUnit, azimuth: distanceResult.azimuth1, azimuthUnit: azimuthUnit, curveType: curveType)! }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make 2 test locations near Antarctica.
        let ushuaia = AGSPointMakeWGS84(-54.6, -68.3)
        let tasmania = AGSPointMakeWGS84(-42, 147)
        
        // The geodesic line between the 2 locations.
        let longPolyline = AGSPolyline(points: [ushuaia, tasmania])
        // Add the line graphic to the overlay.
        let polylineGraphic = AGSGraphic(geometry: longPolyline, symbol: nil)
        linesGraphicsOverlay.graphics.add(polylineGraphic)
        
        // Add the division point graphics to the overlay.
        dotsGraphicsOverlay.graphics.addObjects(from: makeDivisionPoints(point1: ushuaia, point2: tasmania, n: 4).map { AGSGraphic(geometry: $0, symbol: nil) })
        
        // Set viewpoint to see the graphics.
        sceneView.setViewpoint(AGSViewpoint(center: AGSPoint(x: 0, y: -80, spatialReference: .wgs84()), scale: 1e8))
    }
}
