import SwiftUI
import ArcGIS
import ArcGISToolkit

struct ContentView: View {
    let autoPanModes: [AGSLocationDisplayAutoPanMode?] = [nil, .off, .recenter, .navigation, .compassNavigation]
    
    /// An object used for setting up a `SwiftUIMapView`.
    @ObservedObject private var mapViewContext: MapViewContext = {
        /// The graphics overlay used to initialize `MapViewContext`.
        let graphicsOverlay: AGSGraphicsOverlay = {
            let overlay = AGSGraphicsOverlay()
            overlay.renderer = AGSSimpleRenderer(
                symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
            )
            return overlay
        }()
        return MapViewContext(graphicsOverlays: [graphicsOverlay])
    }()
    
    @State private var clearGraphicsButtonDisabled = true
    /// A Boolean that indicates whether the action sheet is presented.
    @State private var showingModes = false
    /// A Boolean that indicates whether the toolkit scale bar is shown.
    @State private var showingScaleBar = false
    
    var body: some View {
        VStack {
            SwiftUIMapView(mapViewContext: mapViewContext)
                .onSingleTap { _, mapPoint in
                    let graphic = AGSGraphic(geometry: mapPoint, symbol: nil)
                    mapViewContext.graphicsOverlays.first!.graphics.add(graphic)
                    updateClearGraphicsButtonState()
                }
                .edgesIgnoringSafeArea(.horizontal)
                .overlay(
                    SwiftUICompass(mapView: mapViewContext.mapView)
                        .frame(width: 30, height: 30)
                        .padding(),
                    alignment: .topTrailing
                )
                .overlay(
                    SwiftUIScalebar(mapView: mapViewContext.mapView, scaleBarStyle: ScalebarStyle.graduatedLine)
                        .frame(width: 200, height: 32)
                        .padding()
                        .background(Color.blue.opacity(0.5))
                        .cornerRadius(24)
                        .opacity(showingScaleBar ? 1 : 0),
                    alignment: .center
                )
            HStack {
                Button("Mode", action: { showingModes = true })
                    .actionSheet(isPresented: $showingModes) {
                        ActionSheet(
                            title: Text("Choose an auto-pan mode."),
                            buttons: autoPanModes.map { mode in
                                .default(Text(label(for: mode)), action: {
                                    guard mode != mapViewContext.autoPanMode else { return }
                                    clearGraphics()
                                    mapViewContext.autoPanMode = mode
                                })
                            } + [.cancel()]
                        )
                    }
                Spacer()
                Toggle("ScaleBar", isOn: $showingScaleBar)
                    .toggleStyle(.button)
                Spacer()
                Button("Clear Graphics", action: clearGraphics)
                    .disabled(clearGraphicsButtonDisabled)
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    func clearGraphics() {
        mapViewContext.graphicsOverlays.first!.graphics.removeAllObjects()
        updateClearGraphicsButtonState()
    }
    
    func updateClearGraphicsButtonState() {
        clearGraphicsButtonDisabled = (mapViewContext.graphicsOverlays.first!.graphics as! [AGSGraphic]).isEmpty
    }
    
    /// Returns a suitable interface label `String` for the mode.
    func label(for autoPanMode: AGSLocationDisplayAutoPanMode?) -> String {
        switch autoPanMode {
        case .off:
            return "No auto pan"
        case .recenter:
            return "Re-Center"
        case .navigation:
            return "Navigation"
        case .compassNavigation:
            return "Compass Navigation"
        case .none:
            return "Disabled"
        @unknown default:
            fatalError("Unknown auto pan mode.")
        }
    }
}

struct DisplayMapSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
