//
//  Map.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 09/08/2020.
//  Copyright © 2020 Petr Budík. All rights reserved.
//

import Foundation

struct Bounds: Decodable {
    var north: Double
    var east: Double
    var south: Double
    var west: Double
}

struct MapConfig: Decodable {
    var bounds: Bounds
    var minZoom: Float
    var maxZoom: Float
}
