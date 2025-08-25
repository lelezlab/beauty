import Foundation
import CoreLocation

final class RegionManager: NSObject, ObservableObject {
    @Published var countryCode: String? = nil     // US / CN
    @Published var country: String? = nil         // United States / 中国
    @Published var administrativeArea: String? = nil // California / 北京市
    @Published var locality: String? = nil        // Los Angeles / 北京

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            manager.requestLocation()
        }
    }

    var displayName: String {
        // e.g., "United States · California · Los Angeles" or "中国 · 北京"
        let parts = [country, administrativeArea, locality].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "全球" : parts.joined(separator: " · ")
    }
}

extension RegionManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fallback to global silently
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let self, let p = placemarks?.first else { return }
            DispatchQueue.main.async { [weak self] in
                self?.countryCode = p.isoCountryCode
                self?.country = p.country
                self?.administrativeArea = p.administrativeArea
                // some regions use locality/subLocality; prefer locality fall back to subLocality
                self?.locality = p.locality ?? p.subLocality
            }
        }
    }
}


