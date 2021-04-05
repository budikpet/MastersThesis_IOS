//
//  MapVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import TangramMap
import ReactiveSwift
import os.log

final class MapVC: BaseViewController {
    private let viewModel: MapViewModeling

    private weak var mapView: TGMapView!

    // MARK: Initializers

    init(viewModel: MapViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        let mapView = TGMapView()
        self.mapView = mapView
        view.addSubview(mapView)
        mapView.mapViewDelegate = self
        mapView.gestureDelegate = self

        mapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        // Updates values inside the scene YAML file
        let sceneUpdates = [
            TGSceneUpdate(path: "global.icon_visible_poi_landuse", value: "true"),
            TGSceneUpdate(path: "sources.mapzen.type", value: "TopoJSON"),                  // TODO: Change to GeoJSON
            TGSceneUpdate(path: "sources.mapzen.url", value: viewModel.mbtilesPath.value),  // Pass on-device path to mbtiles into the mapView
            TGSceneUpdate(path: "sources.mapzen.maxzoom", value: "\(viewModel.mapConfig.value.maxZoom)")
        ]

        mapView.loadSceneAsync(from: viewModel.sceneUrl.value, with: sceneUpdates)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()

        navigationItem.title = "Mapa"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupBindings() {

    }

}

// MARK: TGMapViewDelegate

extension MapVC: TGMapViewDelegate {

    /// Run after scene had been loaded.
    func mapView(_ mapView: TGMapView, didLoadScene sceneID: Int32, withError sceneError: Error?) {
        print("MapView did complete loading")
        let min_zoom = CGFloat(viewModel.mapConfig.value.minZoom)
        mapView.cameraPosition = TGCameraPosition(center: viewModel.currLocation.value, zoom: min_zoom, bearing: 0, pitch: 0)
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
        let zooPragueBounds = viewModel.bounds.value

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
