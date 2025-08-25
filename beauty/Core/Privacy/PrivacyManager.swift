import Foundation

final class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()

    @Published var allowUploadImages: Bool {
        didSet { UserDefaults.standard.set(allowUploadImages, forKey: Keys.allowUploadImages) }
    }
    @Published var allowUploadLocation: Bool {
        didSet { UserDefaults.standard.set(allowUploadLocation, forKey: Keys.allowUploadLocation) }
    }
    @Published var saveChatHistory: Bool {
        didSet { UserDefaults.standard.set(saveChatHistory, forKey: Keys.saveChatHistory) }
    }

    init() {
        self.allowUploadImages = UserDefaults.standard.bool(forKey: Keys.allowUploadImages)
        self.allowUploadLocation = UserDefaults.standard.bool(forKey: Keys.allowUploadLocation)
        self.saveChatHistory = UserDefaults.standard.bool(forKey: Keys.saveChatHistory)
    }

    func wipeAllLocalData() {
        // 开放式清除：清本地偏好；业务数据（图片/缓存）各模块各自实现清理入口
        UserDefaults.standard.removeObject(forKey: Keys.allowUploadImages)
        UserDefaults.standard.removeObject(forKey: Keys.allowUploadLocation)
        UserDefaults.standard.removeObject(forKey: Keys.saveChatHistory)
        allowUploadImages = false
        allowUploadLocation = false
        saveChatHistory = false
    }

    private enum Keys {
        static let allowUploadImages = "privacy.allowUploadImages"
        static let allowUploadLocation = "privacy.allowUploadLocation"
        static let saveChatHistory = "privacy.saveChatHistory"
    }
}


