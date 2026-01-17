//
//  CampusMapView.swift
//  Adventuring Lime
//
//  Created on 2026-01-17.
//

import SwiftUI
import MapKit

struct CampusMapView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            GreyedMapView()
            
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
                }
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
    }
}

// MARK: - Map with Blacked Out Surroundings
struct GreyedMapView: UIViewRepresentable {
    
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
        
        // Add black overlay polygon for areas outside campus
        addBlackoutOverlay(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Keep map top-down if needed
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
        let outerBoundary = [
            CLLocationCoordinate2D(latitude: campusCenter.latitude + 0.1, longitude: campusCenter.longitude - 0.1),
            CLLocationCoordinate2D(latitude: campusCenter.latitude + 0.1, longitude: campusCenter.longitude + 0.1),
            CLLocationCoordinate2D(latitude: campusCenter.latitude - 0.1, longitude: campusCenter.longitude + 0.1),
            CLLocationCoordinate2D(latitude: campusCenter.latitude - 0.1, longitude: campusCenter.longitude - 0.1)
        ]
        
        // Create campus cutout (hole in the overlay)
        let campusCutout = [
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusWest),
            CLLocationCoordinate2D(latitude: campusNorth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusEast),
            CLLocationCoordinate2D(latitude: campusSouth, longitude: campusWest)
        ]
        
        let outerPolygon = MKPolygon(coordinates: outerBoundary, count: outerBoundary.count)
        let innerPolygon = MKPolygon(coordinates: campusCutout, count: campusCutout.count)
        
        // Create polygon with hole (outer boundary with campus cutout)
        let blackoutOverlay = MKPolygon(coordinates: outerBoundary, count: outerBoundary.count, interiorPolygons: [innerPolygon])
        mapView.addOverlay(blackoutOverlay)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GreyedMapView
        
        init(_ parent: GreyedMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.black  // Completely opaque - no street names visible
                renderer.strokeColor = .clear
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Preview
struct CampusMapView_Previews: PreviewProvider {
    static var previews: some View {
        CampusMapView()
    }
}
