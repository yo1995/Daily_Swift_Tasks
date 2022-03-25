// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class ShowDeviceLocationUsingIndoorPositioningViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The label to display location data source info.
    @IBOutlet var sourceStatusLabel: UILabel!
    /// The label to display sensors info.
    @IBOutlet var sensorStatusLabel: UILabel!
    /// The floor level picker view.
    @IBOutlet var floorLevelPickerView: UIPickerView!
    
    // MARK: Properties
    
    /// The measurement formatter for sensor accuracy.
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    /// A indoors location data source based on sensor data, including but not
    /// limited to radio, GPS, motion sensors.
    var indoorsLocationDataSource: AGSIndoorsLocationDataSource?
    
    /// The current floor level reported by the indoors location data source.
    var currentFloor: Int! {
        willSet(newFloor) {
            if newFloor != currentFloor,
               let floorLevel = floorLevels.first(where: { $0.verticalOrder == newFloor }) {
                selectedFloorLevel = floorLevel
            }
        }
    }
    
    /// The floor levels in building M of the floor-aware web map.
    var floorLevels: [AGSFloorLevel] = []
    
    /// Locations for future mock usage.
    var locations: [AGSLocation] = []
    
    /// The currently selected floor level.
    var selectedFloorLevel: AGSFloorLevel! {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                // Set the selected level to visible and the previous to invisible.
                oldValue?.isVisible = false
                selectedFloorLevel.isVisible = true
                // Update picker view selection.
                floorLevelPickerView.selectRow(floorLevels.firstIndex(of: selectedFloorLevel)!, inComponent: 0, animated: true)
            }
        }
    }
    
    // MARK: Methods
    
    /// Load an IPS-enabled web map from a portal.
    func makeMap() -> AGSMap {
        #warning("Please use your webmap item here.")
        // The portal that hosts the IPS-enabled, floor-aware web map.
        let portal = AGSPortal(url: URL(string: "https://example.com/")!, loginRequired: true)
        // WARNING: Never hardcode login information in a production application.
        // This is done solely for the sake of the sample.
        // let credential = AGSCredential(user: "your_user", password: "your_password")
        // portal.credential = credential
        // A floor-aware, IPS-enabled web map for Esri Building M in Redlands.
        let map = AGSMap(item: AGSPortalItem(portal: portal, itemID: "your_portal_ID"))
        map.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.findPositioningTable(map: map)
                self?.loadFloorManager(map: map)
            }
        }
        return map
    }
    
    /// Find the IPS positioning table to set up the location data source.
    func findPositioningTable(map: AGSMap) {
        let tables = map.tables as! [AGSServiceFeatureTable]
        loadTables(tables) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.presentAlert(error: SetupError.failedToLoadFeatureTables)
            case .success:
                if let featureTable = tables.first(where: { $0.tableName == "ips_positioning" }) {
                    self.setupIndoorsLocationDataSource(positioningTable: featureTable)
                } else {
                    self.presentAlert(error: SetupError.positioningTableNotFound)
                }
            }
        }
    }
    
    /// Set up floor manager after the web map is loaded without error.
    func loadFloorManager(map: AGSMap) {
        // The floor manager of the web map, which exposes the sites,
        // facilities, and levels of the floor-aware data model.
        guard let floorManager = map.floorManager else { return }
        floorManager.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.floodManagerDidLoad(floorManager)
            }
        }
    }
    
    /// Called after the floor manager of the web map is loaded without error.
    func floodManagerDidLoad(_ floorManager: AGSFloorManager) {
        #warning("Swap your site IDs here.")
        guard let redlandsSite = floorManager.sites.first(where: { $0.siteID == "1000.US01.MAIN" }),
              let buildingMFacility = redlandsSite.facilities.first(where: { $0.facilityID == "1000.US01.MAIN.M" }),
              let firstFloor = buildingMFacility.levels.first(where: { $0.verticalOrder == 0 }) else { return }
        // Update floor levels and select the first floor.
        floorLevels = buildingMFacility.levels
        selectedFloorLevel = firstFloor
        
        floorLevelPickerView.reloadAllComponents()
        // Change the background color of `UIPickerHighlightView` for demo
        // purpose, which is the 2nd subview of a `UIPickerView` in iOS 15.
        floorLevelPickerView.subviews[1].backgroundColor = .systemBlue.withAlphaComponent(0.6)
        // Set the appearance of the floor level picker view.
        setPickerViewLayout()
    }
    
    /// Set up indoors location data source using IPS positioning table.
    func setupIndoorsLocationDataSource(positioningTable: AGSServiceFeatureTable) {
        // Find the table field name that matches "date created" pattern.
        func isDateCreated(field: AGSField) -> Bool {
            let name = field.name
            return name.caseInsensitiveCompare("DateCreated") == .orderedSame || name.caseInsensitiveCompare("DATE_CREATED") == .orderedSame
        }

        if let dateCreatedFieldName = positioningTable.fields.first(where: isDateCreated(field:))?.name {
            // Create the query parameters.
            let queryParameters = AGSQueryParameters()
            queryParameters.orderByFields = [AGSOrderBy(fieldName: dateCreatedFieldName, sortOrder: .descending)]
            queryParameters.maxFeatures = 1
            // "1=1" will give all the features from the table.
            queryParameters.whereClause = "1=1"

            // Query features from the table to ensure they support IPS.
            positioningTable.queryFeatures(with: queryParameters) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    if let feature = result.featureEnumerator().nextObject(),
                       // The ID that identifies a row in the positioning table.
                       // It is possible to initialize ILDS without globalID,
                       // in which case the first row of the positioning table
                       // will be used.
                       let globalID = feature.attributes[positioningTable.globalIDField] as? UUID,
                       // The network pathways for routing between locations on
                       // the same level.
                       let pathwaysLayer = (self.mapView.map?.operationalLayers as? [AGSFeatureLayer])?.first(where: { $0.name.contains("Pathways") }),
                       let pathwaysTable = pathwaysLayer.featureTable as? AGSArcGISFeatureTable {
                        pathwaysLayer.isVisible = false
                        self.queryFeaturesDidFinish(positioningTable: positioningTable, pathwaysTable: pathwaysTable, globalID: globalID)
                    } else {
                        self.presentAlert(error: SetupError.mapDoesNotSupportIPS)
                    }
                } else if error != nil {
                    self.presentAlert(error: SetupError.failedToLoadIPS)
                }
            }
        } else {
            presentAlert(error: SetupError.dateCreatedFieldNotFound)
        }
    }

    /// Setting up `indoorsLocationDataSource` with positioning, pathways and
    /// positioning ID.
    /// - Parameters:
    ///   - positioningTable: The "ips\_positioning" `AGSServiceFeatureTable`
    ///   from an IPS-enabled map.
    ///   - pathwaysTable: An `ArcGISFeatureTable` that contains pathways as
    ///   per the ArcGIS Indoors Information Model. Setting this property
    ///   enables path snapping of locations provided by the location data source.
    ///   - globalID: An `UUID` which identifies a specific row in the
    ///   positioningTable that should be used for setting up IPS.
    func queryFeaturesDidFinish(positioningTable: AGSServiceFeatureTable, pathwaysTable: AGSArcGISFeatureTable, globalID: UUID) {
        let locationDataSource = AGSIndoorsLocationDataSource(positioningTable: positioningTable, pathwaysTable: pathwaysTable, positioningID: globalID)
        // The delegate which will receive location and status updates
        // from the data source.
        locationDataSource.locationChangeHandlerDelegate = self
        self.indoorsLocationDataSource = locationDataSource
        if let extent = pathwaysTable.extent {
            mapView.setViewpointGeometry(extent) { [unowned self] _ in
                mapView.setViewpointRotation(90)
                mapView.locationDisplay.autoPanMode = .recenter
            }
        }
        mapView.locationDisplay.dataSource = locationDataSource
        // Asynchronously start of the location display, which will in-turn
        // start `indoorsLocationDataSource` to receive IPS updates.
        mapView.locationDisplay.start { [weak self] (error) in
            guard let self = self, let error = error else { return }
            self.presentAlert(error: error)
        }
    }
    
    /// A helper method to load one feature table at a time. Stop loading if
    /// error occurs.
    /// - Parameters:
    ///   - tables: The feature tables to load.
    ///   - completion: The load result for a table.
    func loadTables<C>(_ tables: C, completion: @escaping (Result<Void, Error>) -> Void) where C: RandomAccessCollection, C.Element == AGSFeatureTable {
        guard let table = tables.last else {
            completion(.success(()))
            return
        }
        table.load { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.loadTables(tables.dropLast(), completion: completion)
            }
        }
    }
    
    @objc
    func saveLocations() {
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Get date string to construct filename.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: Date.now)
        let fileURL = documentDirectoryURL.appendingPathComponent("\(dateString)-IPS.json")
        // Encode the stashed locations to a JSON array and write it to disk.
        let codableLocations = locations.compactMap { CodableLocation(location: $0) }
        // Clear stashed locations.
        locations.removeAll()
        do {
            let jsonData = try JSONEncoder().encode(codableLocations)
            try jsonData.write(to: fileURL, options: [.atomic, .noFileProtection])
            presentAlert(title: "Saved at \(dateString)", message: "See the json in Files app.")
        } catch {
            presentAlert(error: error)
        }
    }
    
    // MARK: UI
    
    /// Set the layout for floor picker.
    func setPickerViewLayout() {
        floorLevelPickerView.translatesAutoresizingMaskIntoConstraints = false
        floorLevelPickerView.layer.cornerRadius = 10.0
        NSLayoutConstraint.activate([
            floorLevelPickerView.widthAnchor.constraint(equalToConstant: 80.0),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: floorLevelPickerView.trailingAnchor, multiplier: 1),
            mapView.attributionTopAnchor.constraint(equalToSystemSpacingBelow: floorLevelPickerView.bottomAnchor, multiplier: 1)
        ])
        floorLevelPickerView.isHidden = false
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveLocations))
    }
    
    deinit {
        // Stop location display, which in turn stop the data source.
        mapView.locationDisplay.stop()
        // Reset indoors location data source.
        indoorsLocationDataSource?.locationChangeHandlerDelegate = nil
        indoorsLocationDataSource = nil
    }
}

// MARK: - AGSLocationChangeHandlerDelegate

extension ShowDeviceLocationUsingIndoorPositioningViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Stash the location for mock usage.
        locations.append(location)
        
        // The floor level provided by the indoors beacons.
        let floorText: String
        if let floor = location.additionalSourceProperties[.floor] as? Int {
            currentFloor = floor
            floorText = String(format: "Floor: %@", selectedFloorLevel.longName)
        } else {
            floorText = "Floor not available"
        }
        
        // The horizontal accuracy of the positioning signal from the sensors.
        let horizontalAccuracy = measurementFormatter.string(from: Measurement(value: Double(location.horizontalAccuracy), unit: UnitLength.meters))
        
        // Possible sources: GNSS, AppleIPS, BLE, WIFI, CELL, IP.
        let positionSource = location.additionalSourceProperties[.positionSource] as? String ?? "NA"
        let sensorCount: String = {
            switch positionSource {
            case "GNSS":
                let satelliteCount = location.additionalSourceProperties[.satelliteCount] as? Int ?? 0
                return String(format: "%d satellite(s)", satelliteCount)
            default:
                let transmitterCount = location.additionalSourceProperties[AGSLocationSourcePropertyKey("transmitterCount")] as? Int ?? 0
                return String(format: "%d beacon(s)", transmitterCount)
            }
        }()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sourceStatusLabel.text = String(format: "%@, Position source: %@", floorText, positionSource)
            self.sensorStatusLabel.text = String(format: "%@, Horizontal accuracy: %@", sensorCount, horizontalAccuracy)
        }
    }
    
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, statusDidChange status: AGSLocationDataSourceStatus) {
        switch status {
        case .starting, .started, .stopping, .stopped:
            // - starting: it happens immediately after user starts the location
            // data source. It takes a while to completely start the ILDS.
            // - started: it happens once ILDS successfully started.
            // - stopping: it happens immediately after user stops the location
            // data source. It takes a while to completely stop the ILDS.
            // - stopped: ILDS may stop due to internal error, e.g. user revoked
            // the location permission in system settings. We don't handle these
            // error here.
            break
        case .failedToStart:
            // - failedToStart: This happens if user provides a wrong UUID, or
            // the positioning table has no entries, etc.
            DispatchQueue.main.async { [weak self] in
                if let error = locationDataSource.error {
                    self?.presentAlert(error: error)
                } else {
                    self?.presentAlert(title: "Fail to start ILDS", message: "ILDS failed to start due to an unknown error.")
                }
            }
        @unknown default:
            fatalError("Unknown location data source status.")
        }
    }
}

// MARK: - SetupError

extension ShowDeviceLocationUsingIndoorPositioningViewController {
    private enum SetupError: LocalizedError {
        case dateCreatedFieldNotFound, failedToLoadFeatureTables, failedToLoadIPS, mapDoesNotSupportIPS, noIPSDataFound, positioningTableNotFound
        
        var errorDescription: String? {
            switch self {
            case .dateCreatedFieldNotFound:
                return "DateCreated filed is either missing or has a wrong name."
            case .failedToLoadFeatureTables:
                return "Failed to load feature tables."
            case .failedToLoadIPS:
                return "Failed to load IPS."
            case .mapDoesNotSupportIPS:
                return "Map does not support IPS."
            case .noIPSDataFound:
                return "No IPS data found."
            case .positioningTableNotFound:
                return "Positioning table not found."
            }
        }
    }
}

// MARK: - UIPickerViewDataSource

extension ShowDeviceLocationUsingIndoorPositioningViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        floorLevels.count
    }
}

// MARK: - UIPickerViewDelegate

extension ShowDeviceLocationUsingIndoorPositioningViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        floorLevels[row].shortName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFloorLevel = floorLevels[row]
    }
}
