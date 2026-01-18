//
//  CampusMapView.swift
//  Adventuring Lime
//
//  Created on 2026-01-17.
//

import SwiftUI
import MapKit
import CoreLocation

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
        context.coordinator.attachMapView(mapView)
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
        
        // Map configuration - satellite view with no labels
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
        context.coordinator.restorePathOverlay()
        
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

        // Add a translucent red filter over the campus area
        let campusOverlay = MKPolygon(coordinates: campusCutout, count: campusCutout.count)
        campusOverlay.title = "campusRed"
        mapView.addOverlay(campusOverlay, level: .aboveLabels)
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
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let locationManager = CLLocationManager()
        private weak var mapView: MKMapView?
        private var polyline: MKPolyline?
        private var pathCoordinates: [CLLocationCoordinate2D] = []
        private var showPath = true
        private var lastClearToken = 0
        private let movementThresholdMeters: CLLocationDistance = 5
        private let storageKey = "campusUserPath"

        var parent: GreyedMapView
        
        init(_ parent: GreyedMapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }

        func attachMapView(_ mapView: MKMapView) {
            self.mapView = mapView
            restorePathOverlay()
            startLocationUpdates()
        }

        func setShowPath(_ isVisible: Bool) {
            showPath = isVisible
            if !isVisible, let mapView, let polyline {
                mapView.removeOverlay(polyline)
            } else if isVisible {
                updatePolyline()
                keepPathVisible()
            }
        }

        func handleClearPathToken(_ token: Int) {
            guard token != lastClearToken else { return }
            lastClearToken = token
            clearPath()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                if polygon.title == "campusRed" {
                    renderer.fillColor = UIColor.red.withAlphaComponent(0.35)
                } else {
                    renderer.fillColor = UIColor.black  // Completely opaque - no street names visible
                }
                renderer.strokeColor = .clear
                return renderer
            }
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

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            let coordinate = location.coordinate

            if let last = pathCoordinates.last {
                let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
                if location.distance(from: lastLocation) < movementThresholdMeters {
                    return
                }
            }

            pathCoordinates.append(coordinate)
            persistPath()
            updatePolyline()
            keepPathVisible()
        }

        func startLocationUpdates() {
            locationManager.requestWhenInUseAuthorization()
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }

        func restorePathOverlay() {
            guard let mapView = mapView else { return }
            pathCoordinates = loadPath()
            updatePolyline(on: mapView)
            keepPathVisible()
        }

        private func updatePolyline(on mapView: MKMapView? = nil) {
            guard let mapView = mapView ?? self.mapView else { return }
            if let polyline {
                mapView.removeOverlay(polyline)
            }
            let newLine = MKPolyline(coordinates: pathCoordinates, count: pathCoordinates.count)
            polyline = newLine
            if showPath {
                mapView.addOverlay(newLine, level: .aboveLabels)
            }
        }

        private func keepPathVisible() {
            guard showPath, let mapView, !pathCoordinates.isEmpty else { return }
            let rect = polyline?.boundingMapRect ?? MKMapRect.null
            if !rect.isNull {
                mapView.setVisibleMapRect(
                    rect,
                    edgePadding: UIEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
                    animated: true
                )
            }
        }

        private func persistPath() {
            let stored = pathCoordinates.map { StoredCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
            if let data = try? JSONEncoder().encode(stored) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
        }

        private func clearPath() {
            pathCoordinates.removeAll()
            persistPath()
            if let polyline {
                mapView?.removeOverlay(polyline)
            }
            polyline = nil
        }

        private func loadPath() -> [CLLocationCoordinate2D] {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let stored = try? JSONDecoder().decode([StoredCoordinate].self, from: data) else {
                return []
            }
            return stored.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        }
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
