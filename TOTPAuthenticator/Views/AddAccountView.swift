import SwiftUI
import UIKit

struct AddAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountStore: AccountStore
    
    @State private var showScanner = false
    @State private var showManualInput = false
    @State private var showPhotoPicker = false
    @State private var photo: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 72))
                        .foregroundColor(.blue)
                    
                    Text("添加验证账号")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("扫描二维码或手动输入密钥")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Options
                    VStack(spacing: 16) {
                        Button(action: { showScanner = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                Text("扫描二维码")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: { showPhotoPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title3)
                                Text("从相册选择图片扫码")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: { showManualInput = true }) {
                            HStack {
                                Image(systemName: "keyboard")
                                    .font(.title3)
                                Text("手动输入密钥")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle("添加账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showScanner) {
                ScannerView { result in
                    handleScannedString(result)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $photo)
            }
            .sheet(isPresented: $showManualInput) {
                ManualAddView()
            }
            .onChange(of: photo) { newPhoto in
                guard let image = newPhoto else { return }
                detectQRFromImage(image)
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleScannedString(_ string: String) {
        if let parsed = QRCodeParser.parse(otpAuthURL: string) {
            let account = TOTPAccount(
                issuer: parsed.issuer,
                accountName: parsed.accountName,
                secret: parsed.secret
            )
            accountStore.addAccount(account)
            dismiss()
        } else {
            errorMessage = "无法识别的二维码内容，请确保扫描的是otpauth://二维码"
            showError = true
        }
    }
    
    private func detectQRFromImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            errorMessage = "无法读取图片"
            showError = true
            return
        }
        
        if let qrString = QRCodeParser.detectQRCode(in: ciImage) {
            handleScannedString(qrString)
            showPhotoPicker = false
        } else {
            errorMessage = "这张图片中没有找到二维码，请选择包含二维码的截图"
            showError = true
        }
        photo = nil
    }
}

// MARK: - Manual Input View
struct ManualAddView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountStore: AccountStore
    
    @State private var issuer = ""
    @State private var accountName = ""
    @State private var secret = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("账号信息")) {
                    TextField("发行方 (如: Google, GitHub)", text: $issuer)
                        .autocapitalization(.words)
                    TextField("账号名 (如: user@example.com)", text: $accountName)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("密钥")) {
                    TextField("Base32密钥 (如: JBSWY3DPEHPK3PXP)", text: $secret)
                        .autocapitalization(.none)
                        .keyboardType(.asciiCapable)
                }
                
                Section {
                    Button(action: saveAccount) {
                        Text("添加账号")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("手动添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveAccount() {
        guard !issuer.isEmpty else {
            errorMessage = "请输入发行方"
            showError = true
            return
        }
        guard !accountName.isEmpty else {
            errorMessage = "请输入账号名"
            showError = true
            return
        }
        guard TOTPService.isValidSecret(secret) else {
            errorMessage = "密钥格式不正确，请输入有效的Base32密钥"
            showError = true
            return
        }
        
        let account = TOTPAccount(issuer: issuer, accountName: accountName, secret: secret.uppercased())
        accountStore.addAccount(account)
        dismiss()
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
