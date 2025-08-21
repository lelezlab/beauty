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
						case .success:
							appState.login(with: "apple")
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
		seconds = 60
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
			seconds -= 1
			if seconds <= 0 { t.invalidate(); isSending = false }
		}
	}

	private func login() {
		switch method {
		case .phone:
			appState.login(with: phone)
		case .email:
			appState.login(with: email)
		case .apple:
			break
		}
	}
}

enum AuthMethod: Hashable { case phone, email, apple }

#Preview {
	LoginView().environmentObject(AppState())
}


