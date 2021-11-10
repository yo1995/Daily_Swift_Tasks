import SwiftUI
import ArcGIS
import ArcGISToolkit

class MapViewContext: ObservableObject {
    let mapView: AGSMapView
    
    let map: AGSMap
    let graphicsOverlays: [AGSGraphicsOverlay]
    var autoPanMode: AGSLocationDisplayAutoPanMode?
    
    init(
        map: AGSMap  = .init(basemapStyle: .arcGISTopographic),
        graphicsOverlays: [AGSGraphicsOverlay] = [],
        autoPanMode: AGSLocationDisplayAutoPanMode? = nil
    ) {
        // Initialize the essential components.
        self.mapView = AGSMapView(frame: .zero)
        
        // Initialize the stored properties.
        self.map = map
        self.graphicsOverlays = graphicsOverlays
        self.autoPanMode = autoPanMode
    }
}

struct SwiftUIScalebar<Style>: UIViewRepresentable {
    typealias UIViewType = Scalebar
    
    let mapView: AGSMapView
    let scaleBarStyle: Style
    
    func makeUIView(context: Context) -> Scalebar {
        let scaleBar = Scalebar(mapView: mapView)
        scaleBar.units = Locale.current.usesMetricSystem ? .metric : .imperial
        scaleBar.alignment = .center
        scaleBar.style = scaleBarStyle as! ArcGISToolkit.ScalebarStyle
        return scaleBar
    }

    func updateUIView(_ uiView: Scalebar, context: Context) {
        // Do sth here.
    }
}

struct SwiftUICompass: UIViewRepresentable {
    typealias UIViewType = Compass
    
    let mapView: AGSMapView
    
    func makeUIView(context: Context) -> Compass {
        let compass = Compass(mapView: mapView)
        compass.autoHide = false
        compass.translatesAutoresizingMaskIntoConstraints = false
        return compass
    }

    func updateUIView(_ uiView: Compass, context: Context) {
        // Do sth here.
    }
}
