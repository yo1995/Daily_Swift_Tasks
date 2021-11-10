import SwiftUI

class HostingController: UIHostingController<ContentView> {
    required init?(coder: NSCoder) {
        // `UIHostingController` integrates SwiftUI views into a UIKit
        // view hierarchy. At creation time, specify the SwiftUI as the
        // root view for this view controller.
        super.init(coder: coder, rootView: ContentView())
    }
}
