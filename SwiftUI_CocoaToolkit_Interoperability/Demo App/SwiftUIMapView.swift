import SwiftUI
import ArcGIS

struct SwiftUIMapView {
    /// The context for setting up the `SwiftUIMapView`.
    let mapViewContext: MapViewContext
    
    init(mapViewContext: MapViewContext) {
        self.mapViewContext = mapViewContext
    }
    
    private var onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
}

extension SwiftUIMapView {
    /// Sets a closure to perform when a single tap occurs on the map view.
    /// - Parameter action: The closure to perform upon single tap.
    func onSingleTap(perform action: @escaping (CGPoint, AGSPoint) -> Void) -> Self {
        var copy = self
        copy.onSingleTapAction = action
        return copy
    }
}

extension SwiftUIMapView: UIViewRepresentable {
    typealias UIViewType = AGSMapView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSingleTapAction: onSingleTapAction
        )
    }
    
    func makeUIView(context: Context) -> AGSMapView {
        let uiView = mapViewContext.mapView
        uiView.map = mapViewContext.map
        
        uiView.graphicsOverlays.setArray(mapViewContext.graphicsOverlays)
        
        if let mode = mapViewContext.autoPanMode {
            uiView.locationDisplay.start()
            uiView.locationDisplay.autoPanMode = mode
        }
        
        uiView.touchDelegate = context.coordinator
        return uiView
    }
    
    func updateUIView(_ uiView: AGSMapView, context: Context) {
        if mapViewContext.map != uiView.map {
            uiView.map = mapViewContext.map
        }
        if mapViewContext.graphicsOverlays != uiView.graphicsOverlays as? [AGSGraphicsOverlay] {
            uiView.graphicsOverlays.setArray(mapViewContext.graphicsOverlays)
        }
        if mapViewContext.autoPanMode != uiView.locationDisplay.autoPanMode {
            if mapViewContext.mapView.locationDisplay.started {
                mapViewContext.mapView.locationDisplay.stop()
            }
            
            if let mode = mapViewContext.autoPanMode {
                uiView.locationDisplay.start()
                uiView.locationDisplay.autoPanMode = mode
            }
        }
        
        context.coordinator.onSingleTapAction = onSingleTapAction
    }
}

extension SwiftUIMapView {
    class Coordinator: NSObject {
        var onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
        
        init(
            onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
        ) {
            self.onSingleTapAction = onSingleTapAction
        }
    }
}

extension SwiftUIMapView.Coordinator: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        onSingleTapAction?(screenPoint, mapPoint)
    }
}
