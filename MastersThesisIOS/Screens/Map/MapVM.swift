//
//  MapVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import TangramMap
import ReactiveSwift
import RealmSwift
import os.log

protocol MapViewModelingActions {
    var findShortestPath: Action<(CLLocationCoordinate2D, CLLocationCoordinate2D), ShortestPath, NavigationError> { get }
}

protocol MapViewModeling {
	var actions: MapViewModelingActions { get }

    var sceneUrl: MutableProperty<URL> { get }
    var mbtilesPath: MutableProperty<String> { get }
    var mapConfig: MutableProperty<MapConfig> { get }
    var currLocation: MutableProperty<CLLocationCoordinate2D> { get }
    var destLocation: MutableProperty<CLLocationCoordinate2D?> { get }
    var navigatedPath: ReactiveSwift.Property<[CLLocationCoordinate2D]?> { get }

    var bounds: ReactiveSwift.Property<TGCoordinateBounds> { get }
    var highlightedLocations: MutableProperty<[TGMapFeature]> { get }
    var locationServiceAvailable: MutableProperty<Bool> { get }
    var isUserInMap: MutableProperty<Bool> { get }
    var shouldLocationUpdate: MutableProperty<Bool> { get }
    var selectedProperties: MutableProperty<SelectedMapObjects> { get }
    var dbUpdating: ReactiveSwift.Property<Bool> { get }

    func viewWillAppear()
    func prepareHighlightedLocations(using mapLocations: [MapLocation]) -> [TGMapFeature]
    func getAnimals(fromFeatures features: [TGMapFeature]) -> [AnimalData]
    func navButtonClicked()
    func getPolyline(_ coordinates: [CLLocationCoordinate2D]) -> TGMapFeature
    func shouldHandleTap() -> Bool
}

extension MapViewModeling where Self: MapViewModelingActions {
    var actions: MapViewModelingActions { self }
}

final class MapVM: NSBaseViewModel, MapViewModeling, MapViewModelingActions {
    typealias Dependencies = HasStorageManager & HasLocationManager & HasZooNavigationService
    private let realmDbManager: StorageManaging
    private let locationManager: CLLocationManager
    private let zooNavigationService: ZooNavigationServicing

    // MARK: Actions
    internal var actions: MapViewModelingActions { self }
    internal lazy var findShortestPath: Action<(CLLocationCoordinate2D, CLLocationCoordinate2D), ShortestPath, NavigationError> = zooNavigationService.actions.findShortestPath

    // MARK: Protocol
    internal var sceneUrl: MutableProperty<URL>
    internal var mbtilesPath: MutableProperty<String>
    internal var mapConfig: MutableProperty<MapConfig>
    internal var bounds: ReactiveSwift.Property<TGCoordinateBounds>
    internal var currLocation: MutableProperty<CLLocationCoordinate2D>
    internal var destLocation: MutableProperty<CLLocationCoordinate2D?>
    internal var highlightedLocations: MutableProperty<[TGMapFeature]>
    internal var locationServiceAvailable: MutableProperty<Bool>
    internal var isUserInMap: MutableProperty<Bool>
    internal var shouldLocationUpdate: MutableProperty<Bool>
    internal var selectedProperties: MutableProperty<SelectedMapObjects>
    internal var dbUpdating: ReactiveSwift.Property<Bool>
    internal lazy var navigatedPath: ReactiveSwift.Property<[CLLocationCoordinate2D]?> = ReactiveSwift.Property(initial: nil, then: findShortestPath.values)

    // MARK: Local
    private lazy var animalData: Results<AnimalData> = {
        return realmDbManager.realm.objects(AnimalData.self)
    }()

    private lazy var locations: [Int64: MapLocation] = {
        let res = realmDbManager.realm.objects(MapLocation.self)
        return Dictionary(uniqueKeysWithValues: res.lazy.map { ($0._id, $0) })
    }()

    private let compositeDisposable = CompositeDisposable()

    // MARK: Initializers

    init(dependencies: Dependencies) {
        self.realmDbManager = dependencies.storageManager
        self.locationManager = dependencies.locationManager
        self.zooNavigationService = dependencies.zooNavigationService

        highlightedLocations = MutableProperty([])
        shouldLocationUpdate = MutableProperty(true)
        selectedProperties = MutableProperty(SelectedMapObjects())
        locationServiceAvailable = MutableProperty(false)
        isUserInMap = MutableProperty(false)
        dbUpdating = realmDbManager.actions.updateLocalDB.isExecuting
        mapConfig = MutableProperty(MapVM.loadMapConfig())

//        guard let sceneUrl = Bundle.resources.url(forResource: "bubbleWrapStyle", withExtension: "zip") else { fatalError("Scene file not found.") }
        guard let sceneUrl = Bundle.resources.url(forResource: "bubbleWrapStyle", withExtension: "yaml", subdirectory: "Map/bubbleWrapStyle") else { fatalError("Scene file not found.") }
        self.sceneUrl = MutableProperty(sceneUrl)

        guard let mbtilesPath = Bundle.resources.url(forResource: "defaultZooPrague", withExtension: "mbtiles", subdirectory: "Map")?.path else { fatalError("MBTiles file not found.") }
        self.mbtilesPath = MutableProperty(mbtilesPath)

        bounds = Property(initial: TGCoordinateBounds.init(), then: mapConfig.producer.map() {
            let bounds = $0.bounds
            return TGCoordinateBounds(sw: CLLocationCoordinate2D(latitude: bounds.south, longitude: bounds.west), ne: CLLocationCoordinate2D(latitude: bounds.north, longitude: bounds.east))
        })

        currLocation = MutableProperty(CLLocationCoordinate2D(latitude: 48.117001, longitude: 14.406395))
        destLocation = MutableProperty(nil)

        super.init()
        self.locationManager.delegate = self
        self.locationServiceAvailable.value = self.isLocationServiceAvailable()
        self.isUserInMap.value = self.isUserInMapFunc()

        setupBindings()
    }

    deinit {
        compositeDisposable.dispose()
    }

    private func setupBindings() {
        // Bind changes to current location & destination to the findShortestPath action
        self.findShortestPath <~ currLocation.producer
            .throttle(2.0, on: QueueScheduler.main)
            .compactMap { [weak self] (currLocation) -> (CLLocationCoordinate2D, CLLocationCoordinate2D)? in
                if self?.locationServiceAvailable.value == true, let dest = self?.destLocation.value {
                    return (currLocation, dest)
                } else {
                    return nil
                }
            }
            .observe(on: QueueScheduler())

        // Observe changes in shouldLocationUpdate property, start/stop updating location accordingly
        compositeDisposable += self.shouldLocationUpdate.signal.observeValues { [weak self] (shouldObserve) in
            guard let self = self else { return }
            if(shouldObserve == true) {
                self.locationManager.startUpdatingLocation()
            } else {
                self.locationManager.stopUpdatingLocation()
            }
        }

        // Bind changes in highlighted locations to its property
        self.highlightedLocations.bindingTarget <~ self.selectedProperties.signal
            .filter { $0.allValuesWereChecked() }
            .flatMap(.concat) { (selectedMapObjects: SelectedMapObjects) -> SignalProducer<[TGMapFeature], Never> in
                guard let selectedMapObject = selectedMapObjects.getSelectedMapObject()
                else {
                    return SignalProducer(value: [])
                }

                return SignalProducer(value: selectedMapObject)
                    .compactMap { [weak self] (location, properties) -> [TGMapFeature]? in
                        guard let self = self,
                              let strId = properties["id"],
                              let id = Int64(strId),
                              let mapLocation = self.locations[id]
                        else {
                            return nil

                        }

                        return self.prepareHighlightedLocations(using: [mapLocation])
                    }

            }

        // Bind reseting of highlighted location to reseting destination
        self.destLocation.bindingTarget <~ self.highlightedLocations.signal
            .filter { (highlightedLocations: [TGMapFeature]) in highlightedLocations.isEmpty }
            .map { _ in return nil }

    }
}

// MARK: Protocol
extension MapVM {
    func viewWillAppear() {
        if(!self.isLocationServiceAuthorized()) {
            self.locationManager.requestWhenInUseAuthorization()
        }
        self.shouldLocationUpdate.value = true
    }

    func shouldHandleTap() -> Bool {
        return self.destLocation.value == nil
    }

    /// Navigation button of `MapOptionsPanelView` was clicked.
    /// Starts/stops navigation according to current state.
    func navButtonClicked() {
        if(destLocation.value != nil) {
            // We are currently navigating, stop
            self.destLocation.value = nil
            os_log("Navigation stopped.", log: Logger.appLog(), type: .info)
        } else {
            // Start navigating
            guard let feature = highlightedLocations.value.first else { return }
            let destination = getDestinationPoint(using: feature)
            self.destLocation.value = destination
            os_log("Navigating to feature at [lon: %f, lat: %f]", log: Logger.appLog(), type: .info, destination.longitude, destination.latitude)
        }
    }

    /**
     Constructs `TGMapFeature` objects from `MapLocation` objects.
     */
    func prepareHighlightedLocations(using mapLocations: [MapLocation]) -> [TGMapFeature] {
        let features = mapLocations.compactMap() { mapLocation -> TGMapFeature? in
                guard let geometry = mapLocation.geometry else { return nil }
                let props = ["name": mapLocation.name, "id": "\(mapLocation._id)"]

                if(geometry._type == "Point") {
                    let coord = CLLocationCoordinate2D(latitude: geometry.coordinates[0].coordinates[0].coordinates[1], longitude: geometry.coordinates[0].coordinates[0].coordinates[0])
                    return TGMapFeature(point: coord, properties: props)
                } else if(geometry._type == "Polygon") {
                    let rings: [TGGeoPolyline] = geometry.coordinates.map { (coord2d: Coordinates2D) -> TGGeoPolyline in
                        let coords = Array(coord2d.coordinates).map { (coord1d: Coordinates1D) -> CLLocationCoordinate2D in
                            return CLLocationCoordinate2D(latitude: coord1d.coordinates[1], longitude: coord1d.coordinates[0])
                        }

                        return Array(coords).withUnsafeBufferPointer { (ptr) -> TGGeoPolyline in
                            guard let baseAddress = ptr.baseAddress else { fatalError("Pointer should exist") }
                            return TGGeoPolyline(coordinates: baseAddress, count: UInt(ptr.count))
                        }
                    }

                    return TGMapFeature(polygon: TGGeoPolygon(rings: rings), properties: props)
                } else {
                    fatalError("Should never get polyline.")
                }
            }

        return features
    }

    func getPolyline(_ coordinates: [CLLocationCoordinate2D]) -> TGMapFeature {
        return coordinates.withUnsafeBufferPointer { (ptr) -> TGMapFeature in
            guard let baseAddress = ptr.baseAddress else { fatalError("Pointer should exist") }
            let polyline = TGGeoPolyline(coordinates: baseAddress, count: UInt(ptr.count))
            return TGMapFeature(polyline: polyline, properties: ["type": "shortestPath"])
        }
    }

    func getAnimals(fromFeatures features: [TGMapFeature]) -> [AnimalData] {
        let featureIds = Set(
            features
                .compactMap { $0.properties["id"] }
                .compactMap { strId in Int64(strId) }
        )

        let res = animalData.filter { (animalData: AnimalData) -> Bool in
            let dataIds = Set(animalData.map_locations.map { $0._id })

            return dataIds.intersection(featureIds).isNotEmpty
        }

        return Array(res)
    }
}

// MARK: CLLocationManagerDelegate

extension MapVM: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else { return }
        currLocation.value = first.coordinate
        locationServiceAvailable.value = self.isLocationServiceAvailable()
        isUserInMap.value = self.isUserInMapFunc()

        os_log("Current coordinates: [lon: %f, lat: %f]", log: Logger.appLog(), type: .info, first.coordinate.longitude, first.coordinate.latitude)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Change in permissions occured.
        self.locationServiceAvailable.value = self.isLocationServiceAvailable()
    }
}

// MARK: Helpers

extension MapVM {
    private func isUserInMapFunc() -> Bool {
        let bounds = mapConfig.value.bounds
        let location = self.currLocation.value

        return location.latitude < bounds.north && location.latitude > bounds.south && location.longitude < bounds.east && location.longitude > bounds.west
    }

    private func isLocationServiceAvailable() -> Bool {
        if(!CLLocationManager.locationServicesEnabled()) {
            return false
        }

        return self.isLocationServiceAuthorized()
    }

    private func isLocationServiceAuthorized() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            os_log("Unknown location authorization status used.", log: Logger.appLog(), type: .info)
            return false
        }
    }

    private func getDestinationPoint(using feature: TGMapFeature) -> CLLocationCoordinate2D {
        if let point = feature.point()?.pointee {
            return point
        } else if let polygonCenter = feature.polygon()?.getCenterPoint() {
            return polygonCenter
        } else {
            fatalError("Was unable to get destination point from the feature with properties: \(feature.properties)")
        }
    }

    private static func loadMapConfig() -> MapConfig {
        guard let configFile = Bundle.resources.url(forResource: "defaultConfig", withExtension: "json", subdirectory: "Map") else { fatalError("Config file not found.") }

        do {
            let configData = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(MapConfig.self, from: configData)
        } catch {
            fatalError("Could not load map config.")
        }
    }
}

/**
 Holds properties of selected map objects. It allows us to work with selected map objects as if they came out of one function instead of separate functions.
 The struct is fully populated when properties of all stored map objects are not nil.
 */
struct SelectedMapObjects {
    /// Location and properties of the selected label map object.
    private var label: (CLLocationCoordinate2D?, [String: String]?)

    /// Location and properties of the selected feature map object.
    private var feature: (CLLocationCoordinate2D?, [String: String]?)

    private var allValuesWereEmpty: Bool = false

    /// Check whether all types of map objects were checked.
    /// - Returns: True if all types of map objects were stored in their properties, otherwise false.
    func allValuesWereChecked() -> Bool {
        return (label.1 != nil && feature.1 != nil) || allValuesWereEmpty
    }

    /// Check whether there was any map object selected. Should be called after `SelectedMapObjects.isReadyForHighlighting().`
    /// - Returns: The selected map object or nil if there was no map object selected.
    func getSelectedMapObject() -> (CLLocationCoordinate2D, [String: String])? {

        if let labelProps = label.1, let labelCoord = label.0, label.1.isNotEmpty {
            return (labelCoord, labelProps)
        } else if let featureProps = feature.1, let featureCoord = feature.0, feature.1.isNotEmpty {
            return (featureCoord, featureProps)
        } else {
            return nil
        }
    }

    mutating func resetMapObject() {
        self.label = (nil, nil)
        self.feature = (nil, nil)
    }

    mutating func updateMapObject(ofType type: SelectedMapObjectType, withLocation location: CLLocationCoordinate2D?, properties: [String: String]?) {
        let properties = properties == nil ? [String: String]() : properties

        if(self.allValuesWereChecked()) {
            // Previous values are still set, reset
            self.resetMapObject()
            self.allValuesWereEmpty = false
        }

        switch type {
        case .label:
            self.label = (location, properties)
        case .feature:
            self.feature = (location, properties)
        }

        // Check if all properties are set and if all are empty
        if(self.allValuesWereChecked() && self.getSelectedMapObject() == nil) {
            // We have all values and all are empty, reset
            self.resetMapObject()
            self.allValuesWereEmpty = true
        }
    }
}

enum SelectedMapObjectType {
    case label
    case feature
}
