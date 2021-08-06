import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .oceans())
            mapView.graphicsOverlays.addObjects(from: [linesGraphicsOverlay, dotsGraphicsOverlay])
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
    
    let longPolyline: AGSPolyline = {
        let ushuaia = AGSPointMakeWGS84(-54.6, -68.3)
        let tasmania = AGSPointMakeWGS84(-42, 147)
        return AGSPolyline(points: [ushuaia, tasmania])
    }()
    
    func makeDivisionPoints(polyline: AGSPolyline, n: Int) -> [AGSPoint] {
        let length = AGSGeometryEngine.length(of: polyline)
        return (1..<n).compactMap { AGSGeometryEngine.point(along: polyline, distance: length * Double($0) / Double(n)) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let polylineGraphic = AGSGraphic(geometry: longPolyline, symbol: nil)
        linesGraphicsOverlay.graphics.add(polylineGraphic)
        dotsGraphicsOverlay.graphics.addObjects(from: makeDivisionPoints(polyline: longPolyline, n: 4).map { AGSGraphic(geometry: $0, symbol: nil) })
    }
}
