import SwiftUI
import MapKit
import CoreLocation

extension Notification.Name {
    static let recommendationsOutputUpdated = Notification.Name("RecommendationsOutputUpdated")
}

struct CampusMapView: View {
    @State private var showPath = true
    @State private var showClearConfirm = false
    @State private var clearPathToken = 0
    @State private var selectedRow: [String]? = nil
    @State private var showDetails = false
    @State private var parsedCount: Int = 0
    
    var body: some View {
        ZStack {
            // 1. THE MAP (Base Layer)
            GreyedMapView(showPath: $showPath, clearPathToken: $clearPathToken, selectedRow: $selectedRow, showDetails: $showDetails, parsedCount: $parsedCount)
                .ignoresSafeArea() // Ensure map fills the screen
            
            // 2. UI OVERLAYS
            VStack {
                HStack {
                    Text("Parsed: \(parsedCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
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
                
                // Button remains fixed above Tab Bar
                Button(action: { showClearConfirm = true }) {
                    Text("Clear Path History")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showDetails) {
            VStack(alignment: .leading, spacing: 12) {
                if let fields = selectedRow {
                    if !fields.isEmpty {
                        Text(fields[0])
                            .font(.title2).bold()
                    }
                    if fields.count > 1 {
                        Text(fields[1])
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(fields.enumerated()), id: \.offset) { idx, value in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(value)
                                    .font(.body)
                            }
                        }
                    }
                } else {
                    Text("No details available.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct GreyedMapView: UIViewRepresentable {
    @Binding var showPath: Bool
    @Binding var clearPathToken: Int
    @Binding var selectedRow: [String]?
    @Binding var showDetails: Bool
    @Binding var parsedCount: Int
    
    private let campusCenter = CLLocationCoordinate2D(latitude: 43.661, longitude: -79.395)
    private let testPinCoordinate = CLLocationCoordinate2D(latitude: 43.660837, longitude: -79.396485)
    
    // UPDATED: Increased campus area to 0.05 to push the black walls further out
    private let campusSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.delegate = context.coordinator
        context.coordinator.attachMapView(mapView)
        
        // 🔥 UPDATED: Ultra-tight zoom (0.0015) to ensure the red area fills the screen
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
        let region = MKCoordinateRegion(center: campusCenter, span: initialSpan)
        mapView.setRegion(region, animated: false)
        
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        addBlackoutOverlay(to: mapView)
        addTestPin(to: mapView)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.setShowPath(showPath)
        context.coordinator.handleClearPathToken(clearPathToken)
    }

    private func addBlackoutOverlay(to mapView: MKMapView) {
        let latDelta = campusSpan.latitudeDelta / 2
        let lonDelta = campusSpan.longitudeDelta / 2
        
        let campusNorth = campusCenter.latitude + latDelta
        let campusSouth = campusCenter.latitude - latDelta
        let campusWest = campusCenter.longitude - lonDelta
        let campusEast = campusCenter.longitude + lonDelta
        
        // Massive outer boundary to prevent white map flashing at edges
        let outerMaxLat = campusCenter.latitude + 0.5
        let outerMinLat = campusCenter.latitude - 0.5
        let outerMaxLon = campusCenter.longitude + 0.5
        let outerMinLon = campusCenter.longitude - 0.5
        let outerCornerRadius = 0.01

        let outerBoundary = makeRoundedRectBoundary(
            minLat: outerMinLat, maxLat: outerMaxLat,
            minLon: outerMinLon, maxLon: outerMaxLon,
            radius: outerCornerRadius
        )
        
        let campusCutout = [
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusWest),
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusWest)
        ]
        
        let innerPolygon = MKPolygon(coordinates: campusCutout, count: 4)
        let blackout = MKPolygon(coordinates: outerBoundary, count: outerBoundary.count, interiorPolygons: [innerPolygon])
        blackout.title = "blackout"
        mapView.addOverlay(blackout, level: .aboveLabels)
        
        let redFilter = MKPolygon(coordinates: campusCutout, count: 4)
        redFilter.title = "campusRed"
        mapView.addOverlay(redFilter, level: .aboveLabels)
    }
    
    private func addTestPin(to mapView: MKMapView) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = testPinCoordinate
        annotation.title = "Campus Cafe"
        annotation.subtitle = "Test pin near campus"
        mapView.addAnnotation(annotation)
    }

    private func makeRoundedRectBoundary(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double, radius: Double) -> [CLLocationCoordinate2D] {
        let steps = 6
        var points: [CLLocationCoordinate2D] = []
        let r = min(radius, (maxLat - minLat) / 2, (maxLon - minLon) / 2)

        let corners = [
            (maxLat - r, maxLon - r, 0.0, 90.0),
            (maxLat - r, minLon + r, 90.0, 180.0),
            (minLat + r, minLon + r, 180.0, 270.0),
            (minLat + r, maxLon - r, 270.0, 360.0)
        ]

        for corner in corners {
            for i in 0...steps {
                let angle = (corner.2 + Double(i) * (corner.3 - corner.2) / Double(steps)) * .pi / 180
                points.append(CLLocationCoordinate2D(latitude: corner.0 + r * cos(angle), longitude: corner.1 + r * sin(angle)))
            }
        }
        return points
    }
    
    final class RecommendationAnnotation: MKPointAnnotation {
        let row: [String]
        init(coordinate: CLLocationCoordinate2D, row: [String]) {
            self.row = row
            super.init()
            self.coordinate = coordinate
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let locationManager = CLLocationManager()
        private weak var mapView: MKMapView?
        private var pathCoordinates: [CLLocationCoordinate2D] = []
        private var showPath = true
        private var lastToken = 0
        var parent: GreyedMapView
        
        init(_ parent: GreyedMapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            NotificationCenter.default.addObserver(self, selector: #selector(handleRecommendationsNotification(_:)), name: .recommendationsOutputUpdated, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: .recommendationsOutputUpdated, object: nil)
        }
        
        func attachMapView(_ mapView: MKMapView) {
            self.mapView = mapView
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        func setShowPath(_ val: Bool) { showPath = val; updatePolyline() }
        func handleClearPathToken(_ token: Int) {
            if token != lastToken { lastToken = token; pathCoordinates.removeAll(); updatePolyline() }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = (polygon.title == "campusRed") ? UIColor.red.withAlphaComponent(0.35) : .black
                return renderer
            }
            if let line = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: line)
                renderer.strokeColor = .systemGreen; renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // MARK: - Recommendation Pins Handling
        @objc private func handleRecommendationsNotification(_ notification: Notification) {
            guard let output = notification.userInfo?["output"] as? String else { return }
            let rows = parseRows(from: output)
            parent.parsedCount = rows.count
            print("Recommendations rows parsed: \(rows.count)")
            updatePins(for: rows)
        }

        private func updatePins(for rows: [[String]]) {
            guard let mv = mapView else { return }
            guard !rows.isEmpty else { return }

            DispatchQueue.main.async {
                // Remove existing non-user annotations
                let toRemove = mv.annotations.filter { !($0 is MKUserLocation) }
                mv.removeAnnotations(toRemove)

                // Add one pin per row, jittered around the St. George campus center
                for (idx, row) in rows.enumerated() {
                    let coord = self.jitteredCoordinate(around: self.parent.campusCenter, index: idx)
                    let ann = RecommendationAnnotation(coordinate: coord, row: row)
                    let title = row.first?.isEmpty == false ? row[0] : "Recommended \(idx + 1)"
                    let subtitle = row.indices.contains(1) ? row[1] : "Near campus"
                    ann.title = title
                    ann.subtitle = subtitle
                    mv.addAnnotation(ann)
                }
            }
        }

        private func jitteredCoordinate(around center: CLLocationCoordinate2D, index: Int) -> CLLocationCoordinate2D {
            // Create small, deterministic offsets in a spiral/ring pattern around campus
            let ring = max(1, (index / 6) + 1) // every 6 points, increase ring
            let positionInRing = index % 6
            let angle = (Double(positionInRing) / 6.0) * 2.0 * Double.pi
            let baseOffset: Double = 0.00035 // ~35m
            let radius = baseOffset * Double(ring)
            let dLat = radius * cos(angle)
            let dLon = radius * sin(angle)
            return CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude + dLon)
        }

        // Minimal CSV parsing similar to RecommendationViewModel.parseCSVLine
        private func parseCSVLine(_ line: String) -> [String] {
            var result: [String] = []
            var current = ""
            var inQuotes = false
            var iterator = line.makeIterator()
            while let ch = iterator.next() {
                if ch == "\"" {
                    if inQuotes {
                        if let next = iterator.next() {
                            if next == "\"" { current.append("\"") }
                            else if next == "," { inQuotes = false; result.append(current); current.removeAll(keepingCapacity: true) }
                            else { inQuotes = false; current.append(next) }
                        } else { inQuotes = false }
                    } else { inQuotes = true }
                } else if ch == "," && !inQuotes {
                    result.append(current); current.removeAll(keepingCapacity: true)
                } else {
                    current.append(ch)
                }
            }
            result.append(current)
            return result.map { $0.trimmingCharacters(in: .whitespaces) }
        }

        private func parseRows(from output: String) -> [[String]] {
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return [] }
            if trimmed.contains("\n") || trimmed.contains("\r") {
                let lines = trimmed.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).map(String.init)
                return lines.map { parseCSVLine($0) }.filter { !$0.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            } else {
                // Single-line: treat as one row or chunk every ~12 fields
                let fields = parseCSVLine(trimmed)
                if fields.count >= 11 {
                    var rows: [[String]] = []
                    let size = 12
                    var i = 0
                    while i + size <= fields.count {
                        rows.append(Array(fields[i..<(i+size)]))
                        i += size
                    }
                    if i < fields.count { rows.append(Array(fields[i..<fields.count])) }
                    return rows
                } else {
                    return [fields]
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let identifier = "TestPinMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                view?.glyphImage = UIImage(systemName: "mappin")
                view?.markerTintColor = .systemRed
            } else {
                view?.annotation = annotation
            }
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            if let rec = annotation as? GreyedMapView.RecommendationAnnotation {
                parent.selectedRow = rec.row
            } else {
                let title = annotation.title ?? "Location"
                let subtitle = annotation.subtitle ?? ""
                parent.selectedRow = [title ?? "Location", subtitle ?? ""]
            }
            parent.showDetails = true
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let loc = locations.last else { return }
            pathCoordinates.append(loc.coordinate)
            updatePolyline()
        }
        
        private func updatePolyline() {
            guard let mv = mapView else { return }
            mv.removeOverlays(mv.overlays.filter { $0 is MKPolyline })
            if showPath && !pathCoordinates.isEmpty {
                mv.addOverlay(MKPolyline(coordinates: pathCoordinates, count: pathCoordinates.count))
            }
        }
    }
}

