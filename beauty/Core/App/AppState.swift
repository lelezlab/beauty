import Foundation

final class AppState: ObservableObject {
	@Published var isLoggedIn: Bool {
		didSet { UserDefaults.standard.set(isLoggedIn, forKey: Self.loggedInKey) }
	}

	@Published var phoneNumber: String = ""

	init() {
		self.isLoggedIn = UserDefaults.standard.bool(forKey: Self.loggedInKey)
	}

	func login(with phone: String) {
		phoneNumber = phone
		isLoggedIn = true
	}

	func logout() {
		isLoggedIn = false
		phoneNumber = ""
	}

	private static let loggedInKey = "app.loggedIn"
}


