//
//  MapVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import TangramMap
import ReactiveSwift

final class MapVC: BaseViewController {
    private let viewModel: MapViewModeling

    let min_zoom: CGFloat = CGFloat(17)

    var zooPragueBounds: TGCoordinateBounds?
    var zooPrague: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 50.117001, longitude: 14.406395)

    // MARK: Initializers

    init(viewModel: MapViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()

        navigationItem.title = "Mapa"

        // Init from config
        guard let configFile = Bundle.resources.url(forResource: "config", withExtension: "json") else { fatalError("Config file not found.") }
        let configData = try! Data(contentsOf: configFile)
        let config: Config = try! JSONDecoder().decode(Config.self, from: configData)
        zooPragueBounds = TGCoordinateBounds(sw: CLLocationCoordinate2D(latitude: config.bounds.south, longitude: config.bounds.west), ne: CLLocationCoordinate2D(latitude: config.bounds.north, longitude: config.bounds.east))

        let mapView = self.view as! TGMapView

        mapView.mapViewDelegate = self
        mapView.gestureDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let apiKey = Bundle.main.infoDictionary?["NextzenApiKey"] as! String
        guard let mbtilesPath = Bundle.resources.path(forResource: "zooPrague", ofType: "mbtiles") else { fatalError("MBTiles file not found.") }

        // Updates values inside the scene YAML file
        let sceneUpdates = [
            TGSceneUpdate(path: "global.sdk_api_key", value: apiKey),
            TGSceneUpdate(path: "global.icon_visible_poi_landuse", value: "true"),
            TGSceneUpdate(path: "sources.mapzen.type", value: "TopoJSON"),
            TGSceneUpdate(path: "sources.mapzen.url", value: mbtilesPath),  // Pass on-device path to mbtiles into the mapView
            TGSceneUpdate(path: "sources.mapzen.maxzoom", value: "18")
        ]

        let mapView = self.view as! TGMapView

        guard let sceneUrl = Bundle.resources.url(forResource: "bubble-wrap-style", withExtension: "zip") else { fatalError("Scene file not found.") }

        mapView.loadSceneAsync(from: sceneUrl, with: sceneUpdates)
    }

    private func setupBindings() {

    }

}

// MARK: TGMapViewDelegate

extension MapVC: TGMapViewDelegate {

    /// Run after scene had been loaded.
    func mapView(_ mapView: TGMapView, didLoadScene sceneID: Int32, withError sceneError: Error?) {
        print("MapView did complete loading")

        mapView.cameraPosition = TGCameraPosition(center: zooPrague, zoom: min_zoom, bearing: 0, pitch: 0)
        mapView.minimumZoomLevel = min_zoom
    }

    func mapView(_ mapView: TGMapView, regionDidChangeAnimated animated: Bool) {
        // Puts the map back inside bounds in case scrolling animation gets out of them
        DispatchQueue.main.async { [unowned self] in
            guard let (_, inBoundsCenterCoord) = self.checkBounds(mapView, mapView.cameraPosition.center) else { return }
            mapView.cameraPosition = TGCameraPosition(center: inBoundsCenterCoord, zoom: mapView.zoom, bearing: mapView.bearing, pitch: mapView.pitch)
        }
    }

}

// MARK: TGRecognizerDelegate

extension MapVC: TGRecognizerDelegate {
    /// DIsables rotation
    func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizeRotationGesture location: CGPoint) -> Bool {
        return false
    }

    func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizePanGesture displacement: CGPoint) -> Bool {
        // Coordinates of the center that is closest possible to the map bounds but still inside those bounds
        guard let (_, inBoundsCenterCoord) = self.checkBounds(view, view.cameraPosition.center) else { return true }

        view.cameraPosition = TGCameraPosition(center: inBoundsCenterCoord, zoom: view.zoom, bearing: view.bearing, pitch: view.pitch)
        return false
    }
}

// MARK: Helpers

extension MapVC {
    private func checkBounds(_ view: TGMapView, _ currCenterCoord: CLLocationCoordinate2D) -> (CGPoint, CLLocationCoordinate2D)? {
        let currCenterPos = view.viewPosition(from: view.cameraPosition.center, clipToViewport: false)
        guard let zooPragueBounds = self.zooPragueBounds else { return nil }

        // Coordinates of the current north-western screen location (top-left screen corner)
        let currNW = view.coordinate(fromViewPosition: CGPoint(x: view.bounds.minX, y: view.bounds.minY))
        // Coordinates of the current south-eastern screen location (bottom-right screen corner)
        let currSE = view.coordinate(fromViewPosition: CGPoint(x: view.bounds.maxX, y: view.bounds.maxY))

        // Make local copies of current values
        var inBoundsCenterPos = currCenterPos

        // Check longitude bounds
        if currNW.longitude < zooPragueBounds.sw.longitude {
            inBoundsCenterPos.x = view.viewPosition(from: zooPragueBounds.sw, clipToViewport: false).x + view.bounds.width/2
        } else if currSE.longitude > zooPragueBounds.ne.longitude {
            inBoundsCenterPos.x = view.viewPosition(from: zooPragueBounds.ne, clipToViewport: false).x - view.bounds.width/2
        }

        // Check latitude bounds
        if currNW.latitude > zooPragueBounds.ne.latitude {
            inBoundsCenterPos.y = view.viewPosition(from: zooPragueBounds.ne, clipToViewport: false).y + view.bounds.height/2
        } else if currSE.latitude < zooPragueBounds.sw.latitude {
            inBoundsCenterPos.y = view.viewPosition(from: zooPragueBounds.sw, clipToViewport: false).y - view.bounds.height/2
        }

        if(inBoundsCenterPos.x != currCenterPos.x || inBoundsCenterPos.y != currCenterPos.y) {
            return (inBoundsCenterPos, view.coordinate(fromViewPosition: inBoundsCenterPos))
        }

        return nil
    }
}
