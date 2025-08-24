import SwiftUI
import AuthenticationServices

struct LoginView: View {
	@EnvironmentObject var appState: AppState
	@State private var phone: String = ""
	@State private var email: String = ""
	@State private var code: String = ""
	@State private var isSending: Bool = false
	@State private var seconds: Int = 0
	@State private var method: AuthMethod = .phone

	var body: some View {
		VStack(spacing: 20) {
			Text("登录 beauty").font(.largeTitle).bold()
			Text("深度医美思考 · 快速专业分析").foregroundStyle(.secondary)

			Picker("登录方式", selection: $method) {
				Text("手机号").tag(AuthMethod.phone)
				Text("邮箱").tag(AuthMethod.email)
				Text("Apple ID").tag(AuthMethod.apple)
			}
			.pickerStyle(.segmented)

			Group {
				if method == .phone {
					TextField("手机号", text: $phone)
						.keyboardType(.numberPad)
						.textContentType(.telephoneNumber)
						.padding()
						.background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
					HStack(spacing: 12) {
						TextField("验证码", text: $code)
							.keyboardType(.numberPad)
							.padding()
							.background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
						Button(sendButtonTitle) { sendCode() }
							.buttonStyle(.bordered)
							.disabled(isSending || phone.count < 6)
					}
				} else if method == .email {
					TextField("邮箱", text: $email)
						.keyboardType(.emailAddress)
						.textContentType(.emailAddress)
						.autocapitalization(.none)
						.padding()
						.background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
					HStack(spacing: 12) {
						TextField("验证码", text: $code)
							.keyboardType(.numberPad)
							.padding()
							.background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
						Button(sendButtonTitle) { sendCode() }
							.buttonStyle(.bordered)
							.disabled(isSending || !isValidEmail)
					}
				} else {
					SignInWithAppleButton(.signIn) { request in
						request.requestedScopes = [.fullName, .email]
					} onCompletion: { result in
						switch result {
						case .success(let authorization):
							if let cred = authorization.credential as? ASAuthorizationAppleIDCredential {
								let uid = cred.user
								let email = cred.email
								let name = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }.joined()
								Task {
									var ok = true
									if let token = cred.identityToken { ok = await AuthService.verifyAppleIdentityToken(token) }
									if ok { appState.loginApple(userId: uid, email: email, name: name.isEmpty ? nil : name) }
								}
							} else {
								appState.login(with: "apple")
							}
						case .failure:
							break
						}
					}
					.signInWithAppleButtonStyle(.black)
					.frame(height: 44)
				}
			}

			if method != .apple {
				Button(action: login) {
					Text("登录")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.disabled(!canLogin)
			}

			VStack(alignment: .leading, spacing: 8) {
				Toggle("启用匿名遥测", isOn: Binding(
					get: { BeautyTelemetrySettings.telemetryEnabled },
					set: { BeautyTelemetrySettings.telemetryEnabled = $0 }
				))
				Toggle("加入研究计划（可随时撤回）", isOn: Binding(
					get: { BeautyTelemetrySettings.researchConsent },
					set: { BeautyTelemetrySettings.researchConsent = $0 }
				))
				Toggle("差分隐私噪声", isOn: Binding(
					get: { BeautyTelemetrySettings.differentialPrivacyEnabled },
					set: { BeautyTelemetrySettings.differentialPrivacyEnabled = $0 }
				))
			}

#if DEBUG
			Button {
				appState.login(with: "dev-simulator")
			} label: {
				Text("开发者快速登录（模拟器）")
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.bordered)
#endif
		}
		.padding()
	}

	private var isValidEmail: Bool {
		email.contains("@") && email.contains(".")
	}
	private var canLogin: Bool {
		switch method {
		case .phone: return phone.count >= 6 && code.count >= 4
		case .email: return isValidEmail && code.count >= 4
		case .apple: return false
		}
	}
	private var sendButtonTitle: String { seconds > 0 ? "重发 (\(seconds))" : "发送" }

	private func sendCode() {
		guard !isSending else { return }
		isSending = true
		Task {
			let channel = (method == .phone) ? "phone" : "email"
			let to = (method == .phone) ? phone : email
			let ok = await AuthService.sendOTP(to: to, channel: channel)
			DispatchQueue.main.async {
				if ok {
					seconds = 60
					Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
						seconds -= 1
						if seconds <= 0 { t.invalidate(); isSending = false }
					}
					BeautyTelemetryService.shared.recordConfigChange(.init(source: "auth.otp.send.ok", keys: ["v": 1], labels: ["channel": channel]))
				} else {
					isSending = false
					BeautyTelemetryService.shared.recordConfigChange(.init(source: "auth.otp.send.fail", keys: ["v": 0], labels: ["channel": channel]))
				}
			}
		}
	}

	private func login() {
		Task {
			switch method {
			case .phone:
				let ok = await AuthService.verifyOTP(to: phone, code: code, channel: "phone")
				DispatchQueue.main.async {
					if ok { appState.login(with: phone) }
					BeautyTelemetryService.shared.recordConfigChange(.init(source: ok ? "auth.login.ok" : "auth.login.fail", keys: ["v": ok ? 1 : 0], labels: ["provider": "phone"]))
				}
			case .email:
				let ok = await AuthService.verifyOTP(to: email, code: code, channel: "email")
				DispatchQueue.main.async {
					if ok { appState.login(with: email) }
					BeautyTelemetryService.shared.recordConfigChange(.init(source: ok ? "auth.login.ok" : "auth.login.fail", keys: ["v": ok ? 1 : 0], labels: ["provider": "email"]))
				}
			case .apple:
				break
			}
		}
	}
}

enum AuthMethod: Hashable { case phone, email, apple }

#Preview {
	LoginView().environmentObject(AppState())
}


