//
//  MapVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import TangramMap
import ReactiveSwift

protocol MapViewModelingActions {

}

protocol MapViewModeling {
	var actions: MapViewModelingActions { get }

    var sceneUrl: MutableProperty<URL> { get }
    var mbtilesPath: MutableProperty<String> { get }
    var mapConfig: MutableProperty<MapConfig> { get }
    var currLocation: MutableProperty<CLLocationCoordinate2D> { get }

    var bounds: Property<TGCoordinateBounds> { get }
}

extension MapViewModeling where Self: MapViewModelingActions {
    var actions: MapViewModelingActions { self }
}

final class MapVM: BaseViewModel, MapViewModeling, MapViewModelingActions {
    typealias Dependencies = HasNoDependency

    // MARK: Protocol
    internal var sceneUrl: MutableProperty<URL>
    internal var mbtilesPath: MutableProperty<String>
    internal var mapConfig: MutableProperty<MapConfig>
    internal var bounds: Property<TGCoordinateBounds>
    internal var currLocation: MutableProperty<CLLocationCoordinate2D>

    // MARK: Initializers

    init(dependencies: Dependencies) {
        guard let sceneUrl = Bundle.resources.url(forResource: "bubble-wrap-style", withExtension: "zip") else { fatalError("Scene file not found.") }
        self.sceneUrl = MutableProperty(sceneUrl)

        guard let mbtilesPath = Bundle.resources.path(forResource: "zooPrague", ofType: "mbtiles") else { fatalError("MBTiles file not found.") }
        self.mbtilesPath = MutableProperty(mbtilesPath)

        mapConfig = MutableProperty(MapVM.loadMapConfig())

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

// MARK: Helpers

extension MapVM {
    private static func loadMapConfig() -> MapConfig {
        guard let configFile = Bundle.resources.url(forResource: "config", withExtension: "json") else { fatalError("Config file not found.") }

        do {
            let configData = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(MapConfig.self, from: configData)
        } catch {
            fatalError("Could not load map config.")
        }
    }
}
