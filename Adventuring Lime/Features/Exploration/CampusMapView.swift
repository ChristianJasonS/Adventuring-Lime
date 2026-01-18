import SwiftUI
import MapKit
import CoreLocation

struct CampusMapView: View {
    @State private var showPath = true
    @State private var showClearConfirm = false
    @State private var clearPathToken = 0
    
    var body: some View {
        ZStack {
            // THE MAP (Full Screen)
            GreyedMapView(showPath: $showPath, clearPathToken: $clearPathToken)
                .ignoresSafeArea()
            
            // UI OVERLAYS
            VStack {
                HStack {
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
    }
}

struct GreyedMapView: UIViewRepresentable {
    @Binding var showPath: Bool
    @Binding var clearPathToken: Int
    
    private let campusCenter = CLLocationCoordinate2D(latitude: 43.661, longitude: -79.395)
    private let campusSpan = MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.020)
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Fix for the "Not Full Screen" issue from your screenshots
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.delegate = context.coordinator
        context.coordinator.attachMapView(mapView)
        
        let region = MKCoordinateRegion(center: campusCenter, span: campusSpan)
        mapView.setRegion(region, animated: false)
        
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Restore Dev 1's original overlay setup
        addBlackoutOverlay(to: mapView)
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
        
        // RESTORED: Dev 1's specific boundary and rounding logic
        let outerMaxLat = campusCenter.latitude + 0.1
        let outerMinLat = campusCenter.latitude - 0.1
        let outerMaxLon = campusCenter.longitude + 0.1
        let outerMinLon = campusCenter.longitude - 0.1
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

    // RESTORED: Dev 1's math for rounded highlights
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
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let locationManager = CLLocationManager()
        private weak var mapView: MKMapView?
        private var pathCoordinates: [CLLocationCoordinate2D] = []
        private var showPath = true
        private var lastToken = 0
        var parent: GreyedMapView
        
        init(_ parent: GreyedMapView) { self.parent = parent; super.init(); locationManager.delegate = self }
        
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
