import simd
import XCTest

/// Convert degree value to radian.
/// - Parameter degrees: Degree value.
/// - Returns: Radian value.
func radians(from degrees: Double) -> Double {
    degrees * .pi / 180
}

/// Convert radian value to degree.
/// - Parameter radians: Radian value.
/// - Returns: Degree value.
func degrees(from radians: Double) -> Double {
    radians * 180 / .pi
}

/// The function to get satellite position.
///
/// - Parameters:
///   - longitude: The longitude of GPS receiver location in degrees.
///   - latitude: The latitude of GPS receiver location in degrees.
///   - elevation: The elevation angle in degrees.
///   - azimuth: The azimuth angle in degrees.
///   - satelliteAltitude: The satellite altitude in kilometers.
///   - earthRadius: The earth radius in kilometers.
///
/// - Returns: The resulting longitude and latitude.
func snippet(longitude: Double, latitude: Double, elevation: Double, azimuth: Double, satelliteAltitude: Double = 20200, earthRadius: Double = 6371) -> (Double, Double) {
    // 1. Basic trigonometry
    let r1 = earthRadius
    let r2 = r1 + satelliteAltitude
    let elevationAngle = radians(from: elevation) + .pi / 2
    let inscribedAngle = asin(r1 * sin(elevationAngle) / r2)  // Law of Sines
    let centralAngle = .pi - elevationAngle - inscribedAngle  // Internal angles sum = pi
    
    // 2. Magic of quaternions
    var latLonAxis: simd_double3
    
    let xVector = simd_double3(1, 0, 0)
    let yVector = simd_double3(0, 1, 0)
    let zVector = simd_double3(0, 0, 1)
    
    // Rotate negative latitude angle along y axis.
    let quaternionLatitude = simd_quatd(
        angle: radians(from: -latitude),
        axis: yVector
    )
    latLonAxis = quaternionLatitude.act(xVector)
    // Rotate longitude angle along z axis.
    let quaternionLongitude = simd_quatd(
        angle: radians(from: longitude),
        axis: zVector
    )
    latLonAxis = quaternionLongitude.act(latLonAxis)
    
    // The 3rd axis is on the earth's tangent plane of device location, between
    // device location and North point (z axis)
    var thirdAxis: simd_double3
    if latLonAxis.z == 0 {
        // To avoid division by zero error.
        thirdAxis = simd_double3(0, 0, 1)
    } else {
        thirdAxis = simd_normalize(simd_double3(0, 0, 1 / latLonAxis.z) - latLonAxis)
    }
    // Rotate azimuth angle. Since azimuth is defined as a clockwise angle,
    // it needs to be negative. Also add pi to the result so that it serves
    // as the axis for central angle rotation.
    let quaternionAzimuth = simd_quatd(
        angle: 1.5 * .pi - radians(from: azimuth),
        axis: latLonAxis
    )
    thirdAxis = quaternionAzimuth.act(thirdAxis)
    let quaternionElevation = simd_quatd(
        angle: -centralAngle,
        axis: thirdAxis
    )
    let resultVector = quaternionElevation.act(latLonAxis)
    
    // 3. Print result
    let resultLatitude = degrees(from: .pi / 2 - acos(resultVector.z))
    let resultLongitude = degrees(from: atan2(resultVector.y, resultVector.x))
    return (resultLongitude, resultLatitude)
}

// MARK: - Testcases Below

class SatelliteCoordinatesTests: XCTestCase {
    let accuracy = 1e-3
    
    override func setUp() {
        super.setUp()
    }
    
    /// Normal case: Northern Hemisphere, non-zero coordinates.
    /// - Note:
    /// [Near Redlands, CA](https://www.google.com/maps/place/@34.261,-116.245,11z/)
    func testRedlands() {
        let longitude = -116.245
        let latitude = 34.261
        let elevation = 45.816
        let azimuth = 251.211
        let expectedLongitude = -150.677
        let expectedLatitude = 18.215
        
        let (resultLongitude, resultLatitude) = snippet(longitude: longitude, latitude: latitude, elevation: elevation, azimuth: azimuth)
        XCTAssertEqual(resultLongitude, expectedLongitude, accuracy: accuracy)
        XCTAssertEqual(resultLatitude, expectedLatitude, accuracy: accuracy)
    }
    
    /// Special case: point on the Equator
    /// TBH I don't know how the azimuth angle is defined/measured on the equator. 🤷‍♂️
    /// - Note:
    /// [Quito, Ecuador](https://www.google.com/maps/place/Quito,+Ecuador/@-0.1865938,-78.570625,11z/);
    /// [Azimuth on the Equator](https://stackoverflow.com/questions/25529222/)
    func testEquator() {
        let longitude = -78.613
        // The latitude on the Equator is always 0.
        let latitude = 0.0
        let elevation = 62.123
        let azimuth = 0.103
        let expectedLongitude = -78.573
        let expectedLatitude = 21.440
        
        let (resultLongitude, resultLatitude) = snippet(longitude: longitude, latitude: latitude, elevation: elevation, azimuth: azimuth)
        XCTAssertEqual(resultLongitude, expectedLongitude, accuracy: accuracy)
        XCTAssertEqual(resultLatitude, expectedLatitude, accuracy: accuracy)
    }
    
    /// Normal case: Southern Hemisphere, non-zero coordinates.
    /// It is tricky to get the azimuth angle as it is greater than 180 deg.
    /// - Note:
    /// [Near Sydney](https://www.google.com/maps/place/Sydney+NSW,+Australia/@-33.847927,150.651794,10z/)
    func testSydney() {
        let longitude = 150.553
        let latitude = -33.552
        let elevation = 45.135
        let azimuth = 248.736
        let expectedLongitude = -175.513
        let expectedLatitude = -16.149
        
        let (resultLongitude, resultLatitude) = snippet(longitude: longitude, latitude: latitude, elevation: elevation, azimuth: azimuth)
        XCTAssertEqual(resultLongitude, expectedLongitude, accuracy: accuracy)
        XCTAssertEqual(resultLatitude, expectedLatitude, accuracy: accuracy)
    }
}

SatelliteCoordinatesTests.defaultTestSuite.run()
