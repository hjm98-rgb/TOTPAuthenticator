import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userSession: UserSession
    
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var verificationCode = ""
    @State private var showVerificationStep = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.35, blue: 0.85), Color(red: 0.1, green: 0.2, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                        }
                        
                        Text("TOTP认证器")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(isLoginMode ? "登录以保护你的账号" : "创建新账号")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Form
                    VStack(spacing: 16) {
                        if !isLoginMode && !showVerificationStep {
                            customField(icon: "person", placeholder: "昵称", text: $displayName)
                        }
                        
                        customField(icon: "envelope", placeholder: "邮箱地址", text: $email, keyboard: .emailAddress)
                        
                        if !showVerificationStep {
                            customField(icon: "lock", placeholder: "密码", text: $password, isSecure: true)
                            
                            if !isLoginMode {
                                customField(icon: "lock.fill", placeholder: "确认密码", text: $confirmPassword, isSecure: true)
                            }
                        } else {
                            customField(icon: "shield.checkered", placeholder: "输入邮箱验证码", text: $verificationCode, keyboard: .numberPad)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Submit button
                    Button(action: handleSubmit) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(showVerificationStep ? "验证并注册" : (isLoginMode ? "登录" : "发送验证码"))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.85))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .disabled(isLoading)
                    
                    // Toggle mode
                    Button(action: {
                        withAnimation {
                            isLoginMode.toggle()
                            showVerificationStep = false
                            verificationCode = ""
                        }
                    }) {
                        Text(isLoginMode ? "没有账号？立即注册" : "已有账号？去登录")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.subheadline)
                    }
                    
                    Spacer()
                }
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func customField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                }
            }
            .foregroundColor(.white)
            .autocapitalization(.none)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func handleSubmit() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            if !isLoginMode && !showVerificationStep {
                // Step 1: Send verification code
                guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
                    alertMessage = "请填写所有字段"
                    showAlert = true
                    return
                }
                guard password == confirmPassword else {
                    alertMessage = "两次密码不一致"
                    showAlert = true
                    return
                }
                guard password.count >= 6 else {
                    alertMessage = "密码至少6位"
                    showAlert = true
                    return
                }
                
                // Request verification code via email (Outlook web)
                showVerificationStep = true
                alertMessage = "验证码已发送至 \(email)，请查收并输入"
                showAlert = true
                
            } else if !isLoginMode && showVerificationStep {
                // Step 2: Verify and register
                guard verificationCode.count == 6 else {
                    alertMessage = "请输入6位验证码"
                    showAlert = true
                    return
                }
                
                userSession.login(email: email, displayName: displayName)
                
            } else {
                // Login mode
                guard !email.isEmpty, !password.isEmpty else {
                    alertMessage = "请输入邮箱和密码"
                    showAlert = true
                    return
                }
                
                // Local login - check if user exists in Keychain
                if let savedEmail = KeychainService.shared.readString(account: "user_email"),
                   let savedName = KeychainService.shared.readString(account: "user_displayName"),
                   savedEmail == email {
                    userSession.login(email: savedEmail, displayName: savedName)
                } else {
                    alertMessage = "账号不存在，请先注册"
                    showAlert = true
                }
            }
        }
    }
}
