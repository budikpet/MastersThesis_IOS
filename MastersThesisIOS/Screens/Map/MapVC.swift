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

protocol MapFlowDelegate: class {
    func viewAnimals(_ animals: [AnimalData])
}

final class MapVC: BaseViewController {
    private let viewModel: MapViewModeling

    private weak var highlightedOptionsView: HighlightedOptionsView?
    private weak var mapView: TGMapView!
    private var searchResLayer: TGMapData!
    private var searchHighlightLayer: TGMapData!
    private var currentLocationLayer: TGMapData!
    private var routeLayer: TGMapData!

    public weak var flowDelegate: MapFlowDelegate?

    let compositeDisposable = CompositeDisposable()

    // MARK: Initializers

    init(viewModel: MapViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        compositeDisposable.dispose()
    }

    override func loadView() {
        super.loadView()

        self.prepareMapView()

        let highlightedOptionsView = HighlightedOptionsView(frame: self.view.frame, viewModel: viewModel)
        self.highlightedOptionsView = highlightedOptionsView
        self.view.addSubview(highlightedOptionsView)
        highlightedOptionsView.delegate = self
        highlightedOptionsView.isHidden = true

        highlightedOptionsView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.shouldLocationUpdate.value = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.shouldLocationUpdate.value = false
    }

    private func setupBindings() {
        viewModel.highlightedLocations.signal.observeValues { [weak self] (locations: [TGMapFeature]) in
            /// Show searched map features in the map
            guard let self = self else { return }
            self.highlight(locationsInMap: locations)

            if(locations.isNotEmpty) {
                self.highlightedOptionsView?.showView()
            } else {
                self.highlightedOptionsView?.hideView()
            }
        }

        self.compositeDisposable += viewModel.currLocation.producer.startWithValues { [weak self] (coord: CLLocationCoordinate2D) in
            guard let self = self else { return }
            self.currentLocationLayer.setFeatures([TGMapFeature(point: coord, properties: ["name": "current_location"])])
            self.mapView.requestRender()
        }

        self.compositeDisposable += viewModel.actions.findShortestPath.values
            .observeValues { [weak self] (shortestPath: ShortestPath) in
                guard let self = self else { return }
                let polyline = self.viewModel.getPolyline(shortestPath)

                self.routeLayer.setFeatures([polyline])
                self.mapView.requestRender()
            }
    }

}

// MARK: TGMapViewDelegate

extension MapVC: TGMapViewDelegate {

    func mapView(_ mapView: TGMapView, regionDidChangeAnimated animated: Bool) {
        // Puts the map back inside bounds in case scrolling animation gets out of them
        DispatchQueue.main.async { [unowned self] in
            guard let (_, inBoundsCenterCoord) = self.checkBounds(mapView, mapView.cameraPosition.center) else { return }
            mapView.cameraPosition = TGCameraPosition(center: inBoundsCenterCoord, zoom: mapView.zoom, bearing: mapView.bearing, pitch: mapView.pitch)
        }
    }

    func mapView(_ mapView: TGMapView, didSelectLabel labelPickResult: TGLabelPickResult?, atScreenPosition position: CGPoint) {
        // It is possible to only pick labels explicitly selected with "interactive: true" in the scene file
        // Able to pick pois
        viewModel.selectedProperties.value.updateMapObject(ofType: .label, withLocation: labelPickResult?.coordinate, properties: labelPickResult?.properties)
    }

    func mapView(_ mapView: TGMapView, didSelectFeature feature: [String: String]?, atScreenPosition position: CGPoint) {
        // It is possible to only pick features explicitly selected with "interactive: true" in the scene file
        // Able to pick buildings, roads, landuses
        let coord = mapView.coordinate(fromViewPosition: position)
        viewModel.selectedProperties.value.updateMapObject(ofType: .feature, withLocation: coord, properties: feature)
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

    func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, didRecognizeDoubleTapGesture location: CGPoint) {
        let config = viewModel.mapConfig.value
        let zoom = view.zoom == CGFloat(config.minZoom) ? config.maxZoom : config.minZoom
        guard let pos = TGCameraPosition(center: view.coordinate(fromViewPosition: location), zoom: CGFloat(zoom), bearing: view.bearing, pitch: view.pitch) else { return }
        mapView.setCameraPosition(pos, withDuration: 0.5, easeType: .quint)
    }

    func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, didRecognizeSingleTapGesture location: CGPoint) {
        print("\nLocation: \(location)")
        view.pickLabel(at: location)
        view.pickFeature(at: location)
//        view.pickMarker(at: location)
    }
}

// MARK: HighlightedOptionsViewDelegate

extension MapVC: HighlightedOptionsViewDelegate {
    /**
     Run navigation service to show shortest path to the highlighted feature.
     */
    func navigateClicked(highlightedOptionsView view: HighlightedOptionsView) {
        viewModel.startNavigating()
    }

    /**
     View details of animals that belong into the selected feature (either animal pen or house).
     */
    func showAnimalsClicked(highlightedOptionsView view: HighlightedOptionsView) {
        let animals = viewModel.getAnimals(fromFeatures: viewModel.highlightedLocations.value)
        flowDelegate?.viewAnimals(animals)
    }

    /// Hide button was clicked, hide the view and reset highlighted locations.
    /// - Parameter view: Current HighlightedOptionsView
    func hideClicked(highlightedOptionsView view: HighlightedOptionsView) {
        self.highlightedOptionsView?.hideView()
        self.viewModel.highlightedLocations.value = []
    }
}

// MARK: UI helpers

extension MapVC {
    /// Prepares TGMapView, map layers and other map related variables.
    private func prepareMapView() {
        let mapView = TGMapView()
        self.mapView = mapView
        view.addSubview(mapView)
        mapView.mapViewDelegate = self
        mapView.gestureDelegate = self

        let min_zoom = CGFloat(viewModel.mapConfig.value.minZoom)
        mapView.cameraPosition = TGCameraPosition(center: viewModel.currLocation.value, zoom: min_zoom, bearing: 0, pitch: 0)
        mapView.minimumZoomLevel = min_zoom
        mapView.setPickRadius(CGFloat(30.0))

        mapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        // Updates values inside the scene YAML file
        let sceneUpdates = [
//            TGSceneUpdate(path: "global.icon_visible_poi_landuse", value: "true"),
            TGSceneUpdate(path: "sources.mapzen.type", value: "GeoJSON"),
            TGSceneUpdate(path: "sources.mapzen.url", value: viewModel.mbtilesPath.value),  // Pass on-device path to mbtiles into the mapView
//            TGSceneUpdate(path: "sources.mapzen.max_zoom", value: "\(viewModel.mapConfig.value.maxZoom)"),
            TGSceneUpdate(path: "sources.mapzen.min_display_zoom", value: "\(viewModel.mapConfig.value.minZoom)"),
        ]

        mapView.loadSceneAsync(from: viewModel.sceneUrl.value, with: sceneUpdates)
        searchResLayer = mapView.addDataLayer("mz_search_result", generateCentroid: false)
        searchHighlightLayer = mapView.addDataLayer("highlighted_layer", generateCentroid: false)
        currentLocationLayer = mapView.addDataLayer("mz_current_location", generateCentroid: false)
        routeLayer = mapView.addDataLayer("mz_route_line", generateCentroid: false)
    }
}

// MARK: Helpers

extension MapVC {
    /**
     Updates layers to highlight locations in the map. Creates search pins and actual highlights of polygons.
     - Parameters:
        - locations: A list of locations to be highlighted. Should contain points and/or polygons.
     */
    private func highlight(locationsInMap locations: [TGMapFeature]) {
        let polygons = locations.filter { $0.polygon() != nil }
        let points = locations
            .compactMap { feature -> TGMapFeature? in
                if let _ = feature.point() {
                    return feature
                } else if let polygonCoord = feature.polygon()?.getCenterPoint() {
                    // Get one of polygons points
                    return TGMapFeature(point: polygonCoord, properties: feature.properties)
                }

                return nil
            }

        // Update layers
        self.searchHighlightLayer.setFeatures(polygons)
        self.searchResLayer.setFeatures(points)

        // Move camera
        if let point = points.first?.point()?.pointee {
            let zoom = points.count == 1 ? CGFloat(self.viewModel.mapConfig.value.maxZoom) : CGFloat(self.viewModel.mapConfig.value.minZoom)
            if let pos =  TGCameraPosition(center: point, zoom: zoom, bearing: self.mapView.bearing, pitch: self.mapView.pitch) {
                self.mapView.setCameraPosition(pos, withDuration: 0.25, easeType: .quint)
            }
        }

        self.mapView.requestRender()
    }

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
