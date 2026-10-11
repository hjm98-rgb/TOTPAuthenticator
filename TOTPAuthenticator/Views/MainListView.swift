import SwiftUI

struct MainListView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var userSession: UserSession
    
    @State private var showAddView = false
    @State private var showScanner = false
    @State private var showManualAdd = false
    @State private var copiedCode: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if accountStore.accounts.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("还没有保存的账号")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("点击右上角 + 添加你的第一个验证账号")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else {
                    // Account list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(accountStore.accounts) { account in
                                AccountRowView(account: account, copiedCode: $copiedCode)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        accountStore.objectWillChange.send()
                    }
                }
            }
            .navigationTitle("我的账号")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddView = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive, action: { userSession.logout() }) {
                            Label("退出登录", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddView) {
                AddAccountView()
            }
        }
    }
}

struct AccountRowView: View {
    let account: TOTPAccount
    @Binding var copiedCode: String?
    @State private var showCopiedFeedback = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(String(account.issuer.prefix(1)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.issuer)
                    .font(.headline)
                Text(account.accountName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Code with countdown ring
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Text(account.displayCode)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(codeColor)
                    
                    Button(action: copyCode) {
                        Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.subheadline)
                            .foregroundColor(showCopiedFeedback ? .green : .gray)
                    }
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    Circle()
                        .trim(from: 0, to: CGFloat(account.remainingSeconds) / 30.0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                    Text("\(account.remainingSeconds)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ringColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var codeColor: Color {
        account.remainingSeconds <= 5 ? .red : .primary
    }
    
    private var ringColor: Color {
        account.remainingSeconds <= 5 ? .red : .blue
    }
    
    private func copyCode() {
        UIPasteboard.general.string = account.displayCode
        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedFeedback = false
        }
    }
}
