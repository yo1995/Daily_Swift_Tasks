// swift-tools-version:5.3
/*
 COPYRIGHT 1995-2021 ESRI

 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.

 This material is licensed for use under the Esri Master License
 Agreement (MLA), and is bound by the terms of that agreement.
 You may redistribute and use this code without modification,
 provided you adhere to the terms of the MLA and include this
 copyright notice.

 See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english

 For additional information, contact:
 Environmental Systems Research Institute, Inc.
 Attn: Contracts and Legal Services Department
 380 New York Street
 Redlands, California, USA 92373

 email: contracts@esri.com
 */

import PackageDescription
import FileProvider

// This is setup by default to use a hosted version of the ArcGIS Runtime for iOS.
// To use a local installation of ArcGIS Runtime for iOS, uncomment the lines below declaring
// the `localArcGISPackage` constant and use that as the package dependency instead of the
// hosted version.
let localArcGISPackage = FileManager.default.homeDirectoryForCurrentUser.path.appending("/Library/SDKs/ArcGIS")

let package = Package(
    name: "arcgis-runtime-toolkit-ios",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ArcGISToolkit",
            targets: ["ArcGISToolkit"]
        )
    ],
    dependencies: [
        .package(
            name: "arcgis-runtime-ios",
            path: localArcGISPackage
        )
    ],
    targets: [
        .target(
            name: "ArcGISToolkit",
            dependencies: [.product(name: "ArcGIS", package: "arcgis-runtime-ios")]
        ),
        .testTarget(
            name: "ArcGISToolkitTests",
            dependencies: ["ArcGISToolkit"]
        )
    ]
)
