import SwiftUI
import MapKit
import CoreLocation

struct CampusMapView: View {
    @EnvironmentObject var gameManager: GameManager // Access toggle state
    @State private var showPath = true
    @State private var showClearConfirm = false
    @State private var clearPathToken = 0
    @State private var simulatedCoord = CLLocationCoordinate2D(latitude: 43.661, longitude: -79.395)
    
    // DEMO STEP SIZE (Small for smooth walking)
    private let stepSize = 0.00012
    
    var body: some View {
        ZStack {
            GreyedMapView(showPath: $showPath, clearPathToken: $clearPathToken, simulatedCoord: $simulatedCoord)
            
            // 1. Clear Path Button (TOP CENTER)
            VStack {
                Button(action: { showClearConfirm = true }) {
                    Text("Clear Path History")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white).padding(.vertical, 12).padding(.horizontal, 24)
                        .background(Color.black.opacity(0.6)).clipShape(Capsule())
                }
                .padding(.top, 60) // Spacing for Dynamic Island
                Spacer()
            }

            // 2. D-Pad Controls (HIDDEN BY DEFAULT, Toggled in Profile)
            if gameManager.isDPadEnabled {
                VStack {
                    Spacer()
                    HStack {
                        VStack(spacing: 8) {
                            Button(action: { movePlayer(lat: stepSize, lon: 0) }) { Image(systemName: "chevron.up").dPadStyle() }
                            HStack(spacing: 8) {
                                Button(action: { movePlayer(lat: 0, lon: -stepSize) }) { Image(systemName: "chevron.left").dPadStyle() }
                                Button(action: { movePlayer(lat: 0, lon: stepSize) }) { Image(systemName: "chevron.right").dPadStyle() }
                            }
                            Button(action: { movePlayer(lat: -stepSize, lon: 0) }) { Image(systemName: "chevron.down").dPadStyle() }
                        }
                        .padding(12).background(.ultraThinMaterial).cornerRadius(20)
                        .padding(.leading, 20).padding(.bottom, 100)
                        Spacer()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert("Clear path history?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearPathToken += 1 }
        }
    }
    
    private func movePlayer(lat: Double, lon: Double) {
        withAnimation(.linear(duration: 0.15)) {
            simulatedCoord.latitude += lat
            simulatedCoord.longitude += lon
        }
    }
}

// Helper for D-Pad styling
extension View {
    func dPadStyle() -> some View {
        self.font(.title3.bold()).foregroundColor(.white).frame(width: 40, height: 40)
            .background(Color.orange.opacity(0.8)).clipShape(Circle())
    }
}

// MARK: - The Map View Struct
struct GreyedMapView: UIViewRepresentable {
    @Binding var showPath: Bool
    @Binding var clearPathToken: Int
    @Binding var simulatedCoord: CLLocationCoordinate2D
    
    private let campusCenter = CLLocationCoordinate2D(latitude: 43.661, longitude: -79.395)
    // Large overlay for the Red Tint area
    private let overlaySpan = MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.020)
    // Tight zoom for the camera
    private let cameraZoomSpan = MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = false
        
        // Initial Camera Region
        let region = MKCoordinateRegion(center: campusCenter, span: cameraZoomSpan)
        mapView.setRegion(region, animated: false)
        mapView.mapType = .mutedStandard
        
        // Prevent scrolling into the void
        let boundaryRegion = MKCoordinateRegion(center: campusCenter, span: overlaySpan)
        mapView.setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: boundaryRegion), animated: false)
        
        // Player Marker
        let person = MKPointAnnotation()
        person.coordinate = simulatedCoord
        person.title = "player"
        mapView.addAnnotation(person)
        
        // Setup Polygons & Grid
        context.coordinator.setupGeometry(center: campusCenter, span: overlaySpan)
        context.coordinator.refreshOverlays()
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Animate Player Movement
        if let annotation = uiView.annotations.first(where: { $0.title == "player" }) as? MKPointAnnotation {
            UIView.animate(withDuration: 0.15) { annotation.coordinate = simulatedCoord }
            context.coordinator.updatePath(with: simulatedCoord, showPath: showPath)
        }
        // Handle Clear Path Signal
        if context.coordinator.lastClearToken != clearPathToken {
            context.coordinator.clearPath(); context.coordinator.lastClearToken = clearPathToken
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        var parent: GreyedMapView
        
        // Logic State
        private var exploredMiniTiles: Set<String> = []
        private var pathPoints: [CLLocationCoordinate2D] = []
        private var currentPathOverlay: MKPolyline?
        
        // Grid Logic
        private var largeGridPolygons: [MKPolygon] = []
        private var unlockedGridIndices: Set<Int> = []
        private var tileProgress: [Int: Set<String>] = [:]
        private var campusHole: MKPolygon?
        private var blackout: MKPolygon?
        
        // Demo Counter
        private var tileStepCounter = 0
        
        // How many mini-tiles to unlock a blue square?
        private let tilesToUnlock = 10
        
        var lastClearToken = 0

        init(_ parent: GreyedMapView) { self.parent = parent }

        // 1. SETUP: Create geometry
        func setupGeometry(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
            let latDelta = span.latitudeDelta / 2
            let lonDelta = span.longitudeDelta / 2
            let startLat = center.latitude + latDelta
            let startLon = center.longitude - lonDelta
            
            // Create the "Hole"
            let holeCoords = [
                CLLocationCoordinate2D(latitude: startLat, longitude: startLon),
                CLLocationCoordinate2D(latitude: startLat, longitude: center.longitude + lonDelta),
                CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: center.longitude + lonDelta),
                CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: startLon)
            ]
            self.campusHole = MKPolygon(coordinates: holeCoords, count: 4)
            
            // Create the Blackout Fog
            let outerBoundary = makeRoundedRectBoundary(minLat: center.latitude - 0.1, maxLat: center.latitude + 0.1, minLon: center.longitude - 0.1, maxLon: center.longitude + 0.1, radius: 0.01)
            self.blackout = MKPolygon(coordinates: outerBoundary, count: outerBoundary.count, interiorPolygons: [campusHole!])
            self.blackout!.title = "blackout"
            
            // Create 16 Logical Grid Squares
            largeGridPolygons = []
            let rows = 4; let cols = 4
            let stepLat = span.latitudeDelta / Double(rows)
            let stepLon = span.longitudeDelta / Double(cols)
            
            for r in 0..<rows {
                for c in 0..<cols {
                    let p1 = CLLocationCoordinate2D(latitude: startLat - Double(r)*stepLat, longitude: startLon + Double(c)*stepLon)
                    let p2 = CLLocationCoordinate2D(latitude: startLat - Double(r)*stepLat, longitude: startLon + Double(c+1)*stepLon)
                    let p3 = CLLocationCoordinate2D(latitude: startLat - Double(r+1)*stepLat, longitude: startLon + Double(c+1)*stepLon)
                    let p4 = CLLocationCoordinate2D(latitude: startLat - Double(r+1)*stepLat, longitude: startLon + Double(c)*stepLon)
                    let poly = MKPolygon(coordinates: [p1, p2, p3, p4], count: 4)
                    poly.title = "largeGridTile_\(largeGridPolygons.count)"
                    largeGridPolygons.append(poly)
                }
            }
        }
        
        // 2. DRAW: Render Overlays
        func refreshOverlays() {
            guard let mapView = mapView, let blackout = blackout, let hole = campusHole else { return }
            mapView.removeOverlays(mapView.overlays)
            
            // 1. Blackout
            mapView.addOverlay(blackout, level: .aboveLabels)
            
            // 2. Red Base Tint
            let red = MKPolygon(points: hole.points(), count: hole.pointCount)
            red.title = "campusRed"
            mapView.addOverlay(red, level: .aboveLabels)
            
            // 3. Blue Unlocked Tiles
            for (index, poly) in largeGridPolygons.enumerated() {
                if unlockedGridIndices.contains(index) {
                    poly.title = "unlockedTile"
                    mapView.addOverlay(poly, level: .aboveLabels)
                }
            }
            
            // 4. Grid Lines (Aligned to Polygons)
            var gridLines: [MKPolyline] = []
            for poly in largeGridPolygons {
                let ptr = poly.points()
                let p1 = ptr[0].coordinate; let p2 = ptr[1].coordinate
                let p3 = ptr[2].coordinate; let p4 = ptr[3].coordinate
                gridLines.append(MKPolyline(coordinates: [p1, p2], count: 2))
                gridLines.append(MKPolyline(coordinates: [p2, p3], count: 2))
                gridLines.append(MKPolyline(coordinates: [p3, p4], count: 2))
                gridLines.append(MKPolyline(coordinates: [p4, p1], count: 2))
            }
            let gridOverlay = MKMultiPolyline(gridLines)
            gridOverlay.title = "grid"
            mapView.addOverlay(gridOverlay, level: .aboveLabels)
            
            // 5. Path
            if let path = currentPathOverlay {
                mapView.addOverlay(path, level: .aboveLabels)
            }
        }
        
        // 3. LOGIC: Update Path & Check Unlocks
        func updatePath(with coord: CLLocationCoordinate2D, showPath: Bool) {
            pathPoints.append(coord)
            let miniTileId = "\(Int(coord.latitude*2500))_\(Int(coord.longitude*2500))"
            let mapPoint = MKMapPoint(coord)
            
            if !exploredMiniTiles.contains(miniTileId) {
                exploredMiniTiles.insert(miniTileId)
                
                // DEMO LOGIC: Count steps to trigger Achievement
                tileStepCounter += 1
                Task { @MainActor in
                    GameManager.shared.exploreTile(id: miniTileId)
                    // Trigger "Discovery" every 15 tiles to ensure Achievement Popup shows
                    if tileStepCounter % 15 == 0 {
                        GameManager.shared.discoverPOI(id: "demo_poi_\(tileStepCounter)")
                    }
                }
                
                // Check which Large Grid this mini-tile belongs to
                for (index, poly) in largeGridPolygons.enumerated() {
                    if poly.boundingMapRect.contains(mapPoint) {
                        var set = tileProgress[index] ?? []
                        set.insert(miniTileId)
                        tileProgress[index] = set
                        
                        // Check Unlock Condition
                        if set.count >= tilesToUnlock && !unlockedGridIndices.contains(index) {
                            unlockedGridIndices.insert(index)
                            refreshOverlays() // Redraw to see blue square
                            let gen = UIImpactFeedbackGenerator(style: .heavy)
                            gen.impactOccurred()
                        }
                        break
                    }
                }
            }
            
            // Update Green Line
            if showPath, let mapView = mapView {
                if let old = currentPathOverlay { mapView.removeOverlay(old) }
                let newPath = MKPolyline(coordinates: pathPoints, count: pathPoints.count)
                newPath.title = "path"
                currentPathOverlay = newPath
                mapView.addOverlay(newPath, level: .aboveLabels)
            }
        }
        
        func clearPath() {
            // Clear path data but keep unlocked grid progress
            pathPoints.removeAll()
            if let old = currentPathOverlay { mapView?.removeOverlay(old) }
            currentPathOverlay = nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: poly)
                if poly.title == "blackout" {
                    renderer.fillColor = .black
                } else if poly.title == "campusRed" {
                    renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.25)
                } else if poly.title == "unlockedTile" {
                    renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.4)
                }
                return renderer
            } else if let line = overlay as? MKPolyline, line.title == "path" {
                let r = MKPolylineRenderer(polyline: line); r.strokeColor = .green; r.lineWidth = 3
                return r
            } else if overlay is MKMultiPolyline {
                let r = MKMultiPolylineRenderer(multiPolyline: overlay as! MKMultiPolyline)
                r.strokeColor = UIColor.black.withAlphaComponent(0.5); r.lineWidth = 1
                return r
            }
            return MKOverlayRenderer()
        }
        
        // Helper: Create Geometry for Fog Hole
        private func makeRoundedRectBoundary(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double, radius: Double) -> [CLLocationCoordinate2D] {
            let steps = 6
            var points: [CLLocationCoordinate2D] = []
            let r = min(radius, (maxLat - minLat)/2, (maxLon - minLon)/2)
            points.append(contentsOf: arcPoints(centerLat: maxLat-r, centerLon: maxLon-r, startAngle: 0, endAngle: 90, radius: r, steps: steps))
            points.append(contentsOf: arcPoints(centerLat: maxLat-r, centerLon: minLon+r, startAngle: 90, endAngle: 180, radius: r, steps: steps))
            points.append(contentsOf: arcPoints(centerLat: minLat+r, centerLon: minLon+r, startAngle: 180, endAngle: 270, radius: r, steps: steps))
            points.append(contentsOf: arcPoints(centerLat: minLat+r, centerLon: maxLon-r, startAngle: 270, endAngle: 360, radius: r, steps: steps))
            return points
        }
        private func arcPoints(centerLat: Double, centerLon: Double, startAngle: Double, endAngle: Double, radius: Double, steps: Int) -> [CLLocationCoordinate2D] {
            let step = (endAngle - startAngle) / Double(steps)
            return (0...steps).map { i in
                let angle = (startAngle + Double(i) * step) * .pi / 180
                return CLLocationCoordinate2D(latitude: centerLat + radius * cos(angle), longitude: centerLon + radius * sin(angle))
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
             if annotation.title == "player" {
                 let v = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "player")
                 v.markerTintColor = .orange; v.glyphImage = UIImage(systemName: "person.fill")
                 return v
             }
             return nil
        }
    }
}
