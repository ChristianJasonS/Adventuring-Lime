//
//  CampusMapView.swift
//  Adventuring Lime
//
//  Created on 2026-01-17.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct CampusMapView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showPath = true
    @State private var showClearConfirm = false
    @State private var clearPathToken = 0
    
    var body: some View {
        ZStack {
            GreyedMapView(showPath: $showPath, clearPathToken: $clearPathToken)
            
            // Back button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    Button(action: { showPath.toggle() }) {
                        Image(systemName: showPath ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }

            // Clear path button
            VStack {
                Spacer()
                Button(action: { showClearConfirm = true }) {
                    Text("Clear Path History")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .alert("Clear path history?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearPathToken += 1
            }
        } message: {
            Text("This will delete your saved path and start a new one.")
        }
    }
}

// MARK: - Map with Blacked Out Surroundings
struct GreyedMapView: UIViewRepresentable {
    @Binding var showPath: Bool
    @Binding var clearPathToken: Int
    
    // UofT St. George Campus center
    private let campusCenter = CLLocationCoordinate2D(
        latitude: 43.661,
        longitude: -79.395
    )
    
    // Campus area coverage
    private let campusSpan = MKCoordinateSpan(
        latitudeDelta: 0.018,
        longitudeDelta: 0.020
    )
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.attachMapView(mapView, campusRect: campusMapRect())
        context.coordinator.setShowPath(showPath)
        context.coordinator.handleClearPathToken(clearPathToken)
        
        // Configure map region
        let region = MKCoordinateRegion(center: campusCenter, span: campusSpan)
        mapView.setRegion(region, animated: false)
        
        // Set camera boundaries
        let boundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(boundary, animated: false)
        
        let zoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 200,
            maxCenterCoordinateDistance: 10000
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        // Map configuration - muted standard style
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        
        // Hide all UI elements and labels
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.showsPointsOfInterest = false
        mapView.pointOfInterestFilter = .excludingAll
        
        // Set camera to top-down view
        let camera = MKMapCamera(
            lookingAtCenter: campusCenter,
            fromDistance: 1000,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: false)
        
        // Add overlays
        addBlackoutOverlay(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.setShowPath(showPath)
        context.coordinator.handleClearPathToken(clearPathToken)
    }
    
    private func addBlackoutOverlay(to mapView: MKMapView) {
        // Define campus boundary (roughly rectangular)
        let latDelta = campusSpan.latitudeDelta / 2
        let lonDelta = campusSpan.longitudeDelta / 2
        
        // Campus corners
        let campusNorth = campusCenter.latitude + latDelta
        let campusSouth = campusCenter.latitude - latDelta
        let campusWest = campusCenter.longitude - lonDelta
        let campusEast = campusCenter.longitude + lonDelta
        
        // Create a large outer boundary (much larger than visible area)
        let outerMaxLat = campusCenter.latitude + 0.1
        let outerMinLat = campusCenter.latitude - 0.1
        let outerMaxLon = campusCenter.longitude + 0.1
        let outerMinLon = campusCenter.longitude - 0.1

        // Rounded corner radius in degrees (approx; tuned for visual effect)
        let outerCornerRadius = 0.01

        let outerBoundary = makeRoundedRectBoundary(
            minLat: outerMinLat,
            maxLat: outerMaxLat,
            minLon: outerMinLon,
            maxLon: outerMaxLon,
            radius: outerCornerRadius
        )
        
        // Create campus cutout (hole in the overlay)
        let campusCutout = [
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusWest),
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusWest)
        ]
        
        let innerPolygon = MKPolygon(coordinates: campusCutout, count: campusCutout.count)

        // Create polygon with hole (outer boundary with campus cutout)
        let blackoutOverlay = MKPolygon(coordinates: outerBoundary, count: outerBoundary.count, interiorPolygons: [innerPolygon])
        blackoutOverlay.title = "blackout"
        mapView.addOverlay(blackoutOverlay, level: .aboveLabels)

    }

    private func makeRoundedRectBoundary(
        minLat: CLLocationDegrees,
        maxLat: CLLocationDegrees,
        minLon: CLLocationDegrees,
        maxLon: CLLocationDegrees,
        radius: CLLocationDegrees
    ) -> [CLLocationCoordinate2D] {
        let stepsPerCorner = 6
        var points: [CLLocationCoordinate2D] = []

        let clampedRadius = min(radius, (maxLat - minLat) / 2, (maxLon - minLon) / 2)

        // Top-right corner (0° to 90°)
        points.append(contentsOf: arcPoints(
            centerLat: maxLat - clampedRadius,
            centerLon: maxLon - clampedRadius,
            startAngle: 0,
            endAngle: 90,
            radius: clampedRadius,
            steps: stepsPerCorner
        ))

        // Top-left corner (90° to 180°)
        points.append(contentsOf: arcPoints(
            centerLat: maxLat - clampedRadius,
            centerLon: minLon + clampedRadius,
            startAngle: 90,
            endAngle: 180,
            radius: clampedRadius,
            steps: stepsPerCorner
        ))

        // Bottom-left corner (180° to 270°)
        points.append(contentsOf: arcPoints(
            centerLat: minLat + clampedRadius,
            centerLon: minLon + clampedRadius,
            startAngle: 180,
            endAngle: 270,
            radius: clampedRadius,
            steps: stepsPerCorner
        ))

        // Bottom-right corner (270° to 360°)
        points.append(contentsOf: arcPoints(
            centerLat: minLat + clampedRadius,
            centerLon: maxLon - clampedRadius,
            startAngle: 270,
            endAngle: 360,
            radius: clampedRadius,
            steps: stepsPerCorner
        ))

        return points
    }

    private func arcPoints(
        centerLat: CLLocationDegrees,
        centerLon: CLLocationDegrees,
        startAngle: Double,
        endAngle: Double,
        radius: CLLocationDegrees,
        steps: Int
    ) -> [CLLocationCoordinate2D] {
        guard steps > 0 else { return [] }
        let step = (endAngle - startAngle) / Double(steps)
        return (0...steps).map { i in
            let angle = (startAngle + Double(i) * step) * Double.pi / 180
            let lat = centerLat + radius * cos(angle)
            let lon = centerLon + radius * sin(angle)
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    private func campusMapRect() -> MKMapRect {
        let minLat = campusCenter.latitude - campusSpan.latitudeDelta / 2
        let maxLat = campusCenter.latitude + campusSpan.latitudeDelta / 2
        let minLon = campusCenter.longitude - campusSpan.longitudeDelta / 2
        let maxLon = campusCenter.longitude + campusSpan.longitudeDelta / 2

        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLon))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLon))

        let x = min(topLeft.x, bottomRight.x)
        let y = min(topLeft.y, bottomRight.y)
        let width = abs(topLeft.x - bottomRight.x)
        let height = abs(topLeft.y - bottomRight.y)

        return MKMapRect(x: x, y: y, width: width, height: height)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let locationManager = CLLocationManager()
        private weak var mapView: MKMapView?
        private let dataQueue = DispatchQueue(label: "campus.path.data.queue")
        private let analysisQueue = DispatchQueue(label: "campus.path.analysis.queue", qos: .utility)

        private var analysisTimer: Timer?
        private var polyline: MKPolyline?
        private var pathPoints: [CLLocationCoordinate2D] = []
        private var lastAnalyzedIndex: Int = 0
        private var pendingPolylineUpdate: DispatchWorkItem?

        private var tileDefinitions: [String: TileDefinition] = [:]
        private var tileStates: [String: TileState] = [:]
        private var tileOverlays: [String: MKPolygon] = [:]
        private var campusMapRect: MKMapRect = .null
        private var tileRows: Int = 0
        private var tileCols: Int = 0
        private var pendingTileIds: [String] = []
        private var isAddingTiles = false

        private var campusRedOverlay: MKPolygon?
        private var unlockedTilesOverlay: MKMultiPolygon?
        private var gridOverlay: MKMultiPolyline?

        private var showPath = true
        private var lastClearToken = 0

        private let movementThresholdMeters: CLLocationDistance = 10
        private let tileSizeMeters: Double = 3000
        private let sampleSpacingMeters: Double = 40
        private let unlockThreshold: Double = 0.4

        private lazy var requiredHitsPerTile: Int = {
            let base = Int(tileSizeMeters / sampleSpacingMeters)
            // For small tiles, allow quicker unlocks to avoid never-unlocking grids.
            return max(1, base)
        }()

        private lazy var persistenceURL: URL = {
            let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return base.appendingPathComponent("campus_progress.json")
        }()

        var parent: GreyedMapView

        init(_ parent: GreyedMapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }

        func attachMapView(_ mapView: MKMapView, campusRect: MKMapRect) {
            self.mapView = mapView
            self.campusMapRect = campusRect
            setupTilesAndStateIfNeeded()
            startLocationUpdates()
            startBackgroundAnalyzer()
        }

        func setShowPath(_ isVisible: Bool) {
            showPath = isVisible
            if !isVisible, let mapView, let polyline {
                mapView.removeOverlay(polyline)
            } else if isVisible {
                schedulePolylineUpdate()
            }
        }

        func handleClearPathToken(_ token: Int) {
            guard token != lastClearToken else { return }
            lastClearToken = token
            clearProgress()
        }

        // MARK: - Map Rendering
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // 1️⃣ Blackout overlay
            if let polygon = overlay as? MKPolygon, polygon.title == "blackout" {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.black
                renderer.strokeColor = .clear
                return renderer
            }

            // 2️⃣ Campus red overlay
            if let polygon = overlay as? MKPolygon, polygon.title == "campusRed" {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.45)
                renderer.strokeColor = .clear
                return renderer
            }

            // 3️⃣ Unlocked (blue) tiles
            if let multi = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multi)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.35)
                renderer.strokeColor = .clear
                return renderer
            }

            // 4️⃣ Grid overlay (200m cells)
            if let multiLine = overlay as? MKMultiPolyline {
                let renderer = MKMultiPolylineRenderer(multiPolyline: multiLine)
                renderer.strokeColor = UIColor.black.withAlphaComponent(0.35)
                renderer.lineWidth = 1
                return renderer
            }

            // 4️⃣ Path polyline
            if let line = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: line)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 4
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is MKUserLocation else { return nil }
            let identifier = "LimeUserLocation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.annotation = annotation
            view.subviews.forEach { $0.removeFromSuperview() }

            let containerSize: CGFloat = 40
            let iconSize: CGFloat = 26

            let auraView = UIView(frame: CGRect(x: 0, y: 0, width: containerSize, height: containerSize))
            auraView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.25)
            auraView.layer.cornerRadius = containerSize / 2
            auraView.layer.shadowColor = UIColor.systemYellow.cgColor
            auraView.layer.shadowOpacity = 0.35
            auraView.layer.shadowRadius = 6
            auraView.layer.shadowOffset = .zero
            auraView.isUserInteractionEnabled = false
            view.addSubview(auraView)

            let iconImage = UIImage(named: "LimeIcon")?.withRenderingMode(.alwaysTemplate)
                ?? UIImage(systemName: "leaf.fill")?.withRenderingMode(.alwaysTemplate)
            let iconView = UIImageView(image: iconImage)
            iconView.tintColor = UIColor.systemYellow
            iconView.frame = CGRect(
                x: (containerSize - iconSize) / 2,
                y: (containerSize - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            iconView.contentMode = .scaleAspectFit
            iconView.isUserInteractionEnabled = false
            view.addSubview(iconView)

            view.bounds = CGRect(x: 0, y: 0, width: containerSize, height: containerSize)
            view.centerOffset = .zero
            view.canShowCallout = false
            return view
        }

        // MARK: - Location (Real-Time Layer)
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            let coordinate = location.coordinate

            let shouldAppend = dataQueue.sync { () -> Bool in
                if let last = pathPoints.last {
                    let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
                    if location.distance(from: lastLocation) < movementThresholdMeters {
                        return false
                    }
                }
                pathPoints.append(coordinate)
                return true
            }

            guard shouldAppend else { return }
            schedulePolylineUpdate()
        }

        func startLocationUpdates() {
            locationManager.requestWhenInUseAuthorization()
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }

        // MARK: - Background Analyzer
        private func startBackgroundAnalyzer() {
            analysisTimer?.invalidate()
            analysisTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
                self?.runBackgroundAnalysis()
            }
        }

        private func runBackgroundAnalysis() {
            analysisQueue.async { [weak self] in
                guard let self else { return }

                let snapshot = self.dataQueue.sync { () -> (points: [CLLocationCoordinate2D], startIndex: Int) in
                    (self.pathPoints, self.lastAnalyzedIndex)
                }

                guard snapshot.points.count >= 2, snapshot.startIndex < snapshot.points.count - 1 else { return }

                var tileHitDeltas: [String: Int] = [:]
                let points = snapshot.points

                let startIndex = max(1, snapshot.startIndex)
                for i in startIndex..<points.count {
                    let a = points[i - 1]
                    let b = points[i]
                    self.sampleSegment(from: a, to: b, hits: &tileHitDeltas)
                }

                var newlyUnlockedIds: [String] = []
                self.dataQueue.sync {
                    self.lastAnalyzedIndex = points.count - 1
                    for (tileId, delta) in tileHitDeltas {
                        guard var state = self.tileStates[tileId], !state.isUnlocked else { continue }
                        state.hitCount += delta
                        let ratio = Double(state.hitCount) / Double(self.requiredHitsPerTile)
                        if ratio >= self.unlockThreshold {
                            state.isUnlocked = true
                            newlyUnlockedIds.append(tileId)
                        }
                        self.tileStates[tileId] = state
                    }
                }

                if !newlyUnlockedIds.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        self?.rebuildTileOverlays()
                    }
                }

                self.persistState()
            }
        }

        private func sampleSegment(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, hits: inout [String: Int]) {
            let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
            let distance = endLocation.distance(from: startLocation)
            guard distance > 0 else { return }

            let steps = Int(floor(distance / sampleSpacingMeters))
            guard steps > 0 else { return }

            for step in 1...steps {
                let t = (Double(step) * sampleSpacingMeters) / distance
                let lat = start.latitude + (end.latitude - start.latitude) * t
                let lon = start.longitude + (end.longitude - start.longitude) * t
                let point = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                if let tileId = tileId(for: point) {
                    hits[tileId, default: 0] += 1
                }
            }
        }

        // MARK: - Tiles
        private func setupTilesAndStateIfNeeded() {
            guard let mapView, tileDefinitions.isEmpty, !campusMapRect.isNull else { return }

            generateTileGrid()

            if let persisted = loadState() {
                pathPoints = persisted.path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                lastAnalyzedIndex = persisted.lastAnalyzedIndex
                for id in tileDefinitions.keys {
                    let hitCount = persisted.tileHitCounts[id] ?? 0
                    let unlocked = persisted.unlockedTileIds.contains(id)
                    tileStates[id] = TileState(hitCount: hitCount, isUnlocked: unlocked || hitCount >= requiredHitsPerTile)
                }
            } else {
                for id in tileDefinitions.keys {
                    tileStates[id] = TileState(hitCount: 0, isUnlocked: false)
                }
            }

            pendingTileIds = tileDefinitions.keys.sorted()
            addCampusRedOverlayIfNeeded(on: mapView)
            addGridOverlayIfNeeded(on: mapView)
            addNextTileBatch(on: mapView)
            schedulePolylineUpdate()
        }

        private func generateTileGrid() {
            tileDefinitions.removeAll()
            tileOverlays.removeAll()

            tileCols = Int(ceil(campusMapRect.size.width / tileSizeMeters))
            tileRows = Int(ceil(campusMapRect.size.height / tileSizeMeters))

            for row in 0..<tileRows {
                for col in 0..<tileCols {
                    let originX = campusMapRect.origin.x + Double(col) * tileSizeMeters
                    let originY = campusMapRect.origin.y + Double(row) * tileSizeMeters
                    let width = min(tileSizeMeters, campusMapRect.maxX - originX)
                    let height = min(tileSizeMeters, campusMapRect.maxY - originY)
                    guard width > 0, height > 0 else { continue }

                    let rect = MKMapRect(x: originX, y: originY, width: width, height: height)
                    let id = "\(row)_\(col)"
                    tileDefinitions[id] = TileDefinition(id: id, rect: rect, row: row, col: col)
                }
            }
        }

        private func tileId(for point: MKMapPoint) -> String? {
            guard !campusMapRect.isNull else { return nil }
            let dx = point.x - campusMapRect.minX
            let dy = point.y - campusMapRect.minY
            if dx < 0 || dy < 0 { return nil }
            let col = Int(floor(dx / tileSizeMeters))
            let row = Int(floor(dy / tileSizeMeters))
            guard row >= 0, col >= 0, row < tileRows, col < tileCols else { return nil }
            return "\(row)_\(col)"
        }

        private func rebuildTileOverlays() {
            guard let mapView else { return }
            if let unlockedTilesOverlay {
                mapView.removeOverlay(unlockedTilesOverlay)
            }

            let unlockedPolygons = tileDefinitions.values.compactMap { tile -> MKPolygon? in
                guard tileStates[tile.id]?.isUnlocked == true else { return nil }
                return makeTilePolygon(for: tile)
            }

            let unlockedOverlay = MKMultiPolygon(unlockedPolygons)
            unlockedTilesOverlay = unlockedOverlay

            mapView.addOverlay(unlockedOverlay, level: .aboveRoads)
        }

        private func addNextTileBatch(on mapView: MKMapView) {
            guard !isAddingTiles else { return }
            isAddingTiles = true

            let batchSize = 200
            let batch = pendingTileIds.prefix(batchSize)
            pendingTileIds.removeFirst(min(batchSize, pendingTileIds.count))

            for id in batch {
                if let tile = tileDefinitions[id] {
                    let overlay = makeTilePolygon(for: tile)
                    tileOverlays[id] = overlay
                }
            }

            isAddingTiles = false

            if !pendingTileIds.isEmpty {
                DispatchQueue.main.async { [weak self, weak mapView] in
                    guard let self, let mapView else { return }
                    self.addNextTileBatch(on: mapView)
                }
            } else {
                rebuildTileOverlays()
            }
        }

        private func makeTilePolygon(for tile: TileDefinition) -> MKPolygon {
            let rect = tile.rect
            let topLeft = MKMapPoint(x: rect.minX, y: rect.minY).coordinate
            let topRight = MKMapPoint(x: rect.maxX, y: rect.minY).coordinate
            let bottomRight = MKMapPoint(x: rect.maxX, y: rect.maxY).coordinate
            let bottomLeft = MKMapPoint(x: rect.minX, y: rect.maxY).coordinate

            let coords = [topLeft, topRight, bottomRight, bottomLeft]
            return MKPolygon(coordinates: coords, count: coords.count)
        }

        private func addCampusRedOverlayIfNeeded(on mapView: MKMapView) {
            guard campusRedOverlay == nil else { return }

            let topLeft = MKMapPoint(x: campusMapRect.minX, y: campusMapRect.minY).coordinate
            let topRight = MKMapPoint(x: campusMapRect.maxX, y: campusMapRect.minY).coordinate
            let bottomRight = MKMapPoint(x: campusMapRect.maxX, y: campusMapRect.maxY).coordinate
            let bottomLeft = MKMapPoint(x: campusMapRect.minX, y: campusMapRect.maxY).coordinate

            let coords = [topLeft, topRight, bottomRight, bottomLeft]
            let polygon = MKPolygon(coordinates: coords, count: coords.count)
            polygon.title = "campusRed"
            campusRedOverlay = polygon
            mapView.addOverlay(polygon, level: .aboveRoads)
        }

        private func addGridOverlayIfNeeded(on mapView: MKMapView) {
            guard gridOverlay == nil else { return }

            var lines: [MKPolyline] = []
            let minX = campusMapRect.minX
            let maxX = campusMapRect.maxX
            let minY = campusMapRect.minY
            let maxY = campusMapRect.maxY

            var x = minX
            while x <= maxX {
                let top = MKMapPoint(x: x, y: minY).coordinate
                let bottom = MKMapPoint(x: x, y: maxY).coordinate
                lines.append(MKPolyline(coordinates: [top, bottom], count: 2))
                x += tileSizeMeters
            }

            var y = minY
            while y <= maxY {
                let left = MKMapPoint(x: minX, y: y).coordinate
                let right = MKMapPoint(x: maxX, y: y).coordinate
                lines.append(MKPolyline(coordinates: [left, right], count: 2))
                y += tileSizeMeters
            }

            let multi = MKMultiPolyline(lines)
            gridOverlay = multi
            mapView.addOverlay(multi, level: .aboveRoads)
        }

        // MARK: - Path Overlay
        private func schedulePolylineUpdate() {
            pendingPolylineUpdate?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                let points = self.snapshotPathPoints()
                self.updatePolyline(with: points)
            }
            pendingPolylineUpdate = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
        }

        private func updatePolyline(with points: [CLLocationCoordinate2D]) {
            guard let mapView else { return }
            if let polyline {
                mapView.removeOverlay(polyline)
            }
            let newLine = MKPolyline(coordinates: points, count: points.count)
            polyline = newLine
            if showPath {
                mapView.addOverlay(newLine, level: .aboveLabels)
            }
        }

        private func snapshotPathPoints() -> [CLLocationCoordinate2D] {
            dataQueue.sync { pathPoints }
        }

        // MARK: - Persistence
        private func persistState() {
            let storedPath = dataQueue.sync { pathPoints.map { StoredCoordinate(latitude: $0.latitude, longitude: $0.longitude) } }
            let unlocked = tileStates.filter { $0.value.isUnlocked }.map { $0.key }
            let state = PersistedState(
                path: storedPath,
                unlockedTileIds: unlocked,
                lastAnalyzedIndex: dataQueue.sync { lastAnalyzedIndex },
                tileHitCounts: tileStates.mapValues { $0.hitCount }
            )

            if let data = try? JSONEncoder().encode(state) {
                try? data.write(to: persistenceURL, options: [.atomic])
            }
        }

        private func loadState() -> PersistedState? {
            guard let data = try? Data(contentsOf: persistenceURL) else { return nil }
            return try? JSONDecoder().decode(PersistedState.self, from: data)
        }

        private func clearProgress() {
            dataQueue.sync {
                pathPoints.removeAll()
                lastAnalyzedIndex = 0
            }
            if let polyline {
                mapView?.removeOverlay(polyline)
            }
            polyline = nil

            for id in tileDefinitions.keys {
                tileStates[id] = TileState(hitCount: 0, isUnlocked: false)
            }
            rebuildTileOverlays()
            persistState()
        }
    }

    private struct TileDefinition {
        let id: String
        let rect: MKMapRect
        let row: Int
        let col: Int
    }

    private struct TileState {
        var hitCount: Int
        var isUnlocked: Bool
    }

    private struct PersistedState: Codable {
        let path: [StoredCoordinate]
        let unlockedTileIds: [String]
        let lastAnalyzedIndex: Int
        let tileHitCounts: [String: Int]
    }

    private struct StoredCoordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
}

// MARK: - Preview
struct CampusMapView_Previews: PreviewProvider {
    static var previews: some View {
        CampusMapView()
    }
}
