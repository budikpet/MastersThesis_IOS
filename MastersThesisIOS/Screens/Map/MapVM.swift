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

protocol MapViewModelingActions {

}

protocol MapViewModeling {
	var actions: MapViewModelingActions { get }

    var sceneUrl: MutableProperty<URL> { get }
    var mbtilesPath: MutableProperty<String> { get }
    var mapConfig: MutableProperty<MapConfig> { get }
    var currLocation: MutableProperty<CLLocationCoordinate2D> { get }

    var bounds: ReactiveSwift.Property<TGCoordinateBounds> { get }
    var highlightedLocations: MutableProperty<[TGMapFeature]> { get }

    func highlightLocations(using mapLocations: [MapLocation])
    func highlightLocations(using properties: [String: String]?, at coord: CLLocationCoordinate2D?, canUseNil: Bool)
}

extension MapViewModeling where Self: MapViewModelingActions {
    var actions: MapViewModelingActions { self }
}

final class MapVM: BaseViewModel, MapViewModeling, MapViewModelingActions {
    typealias Dependencies = HasRealmDBManager
    private let realmDbManager: RealmDBManaging

    // MARK: Protocol
    internal var sceneUrl: MutableProperty<URL>
    internal var mbtilesPath: MutableProperty<String>
    internal var mapConfig: MutableProperty<MapConfig>
    internal var bounds: ReactiveSwift.Property<TGCoordinateBounds>
    internal var currLocation: MutableProperty<CLLocationCoordinate2D>
    internal var highlightedLocations: MutableProperty<[TGMapFeature]>

    // MARK: Local
    private lazy var locations: [Int64: MapLocation] = {
        let res = realmDbManager.realm.objects(MapLocation.self)
        return Dictionary(uniqueKeysWithValues: res.lazy.map { ($0._id, $0) })
    }()

    // MARK: Initializers

    init(dependencies: Dependencies) {
        self.realmDbManager = dependencies.realmDBManager

        highlightedLocations = MutableProperty([])
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

        currLocation = MutableProperty(CLLocationCoordinate2D(latitude: 50.117001, longitude: 14.406395))

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: Protocol
extension MapVM {
    /**
     Constructs `TGMapFeature` objects from `MapLocation` objects.
     */
    func highlightLocations(using mapLocations: [MapLocation]) {
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

        self.highlightedLocations.value = features
    }

    /**
     Constructs `TGMapFeature` objects using data from manually picked location.
     */
    func highlightLocations(using properties: [String: String]?, at coord: CLLocationCoordinate2D?, canUseNil: Bool = false) {
        if(canUseNil && properties == nil) {
            highlightLocations(using: [])
            return
        }

        guard let strId = properties?["id"] else { return }
        guard let id = Int64(strId) else { return }
        guard let mapLocation = locations[id] else { return }

        highlightLocations(using: [mapLocation])
    }
}

// MARK: Helpers

extension MapVM {
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
