import Foundation

final class AppState: ObservableObject {
	@Published var isLoggedIn: Bool {
		didSet { UserDefaults.standard.set(isLoggedIn, forKey: Self.loggedInKey) }
	}

	@Published var phoneNumber: String = "" {
		didSet { UserDefaults.standard.set(phoneNumber, forKey: Self.phoneKey) }
	}
	@Published var userId: String = "" {
		didSet { UserDefaults.standard.set(userId, forKey: Self.userIdKey) }
	}
	@Published var email: String = "" {
		didSet { UserDefaults.standard.set(email, forKey: Self.emailKey) }
	}
	@Published var displayName: String = "" {
		didSet { UserDefaults.standard.set(displayName, forKey: Self.displayNameKey) }
	}
	@Published var authProvider: String = "" {
		didSet { UserDefaults.standard.set(authProvider, forKey: Self.authProviderKey) }
	}

	init() {
		self.isLoggedIn = UserDefaults.standard.bool(forKey: Self.loggedInKey)
		self.phoneNumber = UserDefaults.standard.string(forKey: Self.phoneKey) ?? ""
		self.userId = UserDefaults.standard.string(forKey: Self.userIdKey) ?? ""
		self.email = UserDefaults.standard.string(forKey: Self.emailKey) ?? ""
		self.displayName = UserDefaults.standard.string(forKey: Self.displayNameKey) ?? ""
		self.authProvider = UserDefaults.standard.string(forKey: Self.authProviderKey) ?? ""
	}

	func login(with phone: String) {
		if phone.contains("@") {
			email = phone
			authProvider = "email"
		} else {
			phoneNumber = phone
			authProvider = "phone"
		}
		isLoggedIn = true
	}

	func loginApple(userId: String, email: String?, name: String?) {
		self.userId = userId
		self.email = email ?? self.email
		self.displayName = name ?? self.displayName
		self.authProvider = "apple"
		self.isLoggedIn = true
	}

	func logout() {
		isLoggedIn = false
		phoneNumber = ""
		userId = ""
		email = ""
		displayName = ""
		authProvider = ""
	}

	private static let loggedInKey = "app.loggedIn"
	private static let phoneKey = "app.phone"
	private static let userIdKey = "app.userId"
	private static let emailKey = "app.email"
	private static let displayNameKey = "app.displayName"
	private static let authProviderKey = "app.authProvider"
}


