import UIKit
import ArcGIS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Authentication with an API key or named user is required to
        // access basemaps and other location services.
        AGSArcGISRuntimeEnvironment.apiKey = <#your_API_key#>
        print("Current SDK build is \(Bundle.ArcGISSDKVersionString)")
        return true
    }
}

extension Bundle {
    private static let agsBundle = AGSBundle()
    
    /// An end-user printable string representation of the ArcGIS Bundle version shipped with the app.
    ///
    /// For example, "2883"
    static var sdkBundleVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the ArcGIS Runtime SDK version shipped with the app.
    ///
    /// For example, "100.9.0"
    static var sdkVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    /// Builds an end-user printable string representation of the ArcGIS Bundle shipped with the app.
    ///
    /// For example, "ArcGIS Runtime SDK 100.9.0 (2883)"
    static var ArcGISSDKVersionString: String {
        return String(format: "ArcGIS Runtime SDK %@ (%@)", sdkVersion, sdkBundleVersion)
    }
}
