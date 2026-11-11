import SwiftUI

struct AuthenticationView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    @State private var draft = SignInDraft()
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text("petlife")
                        .font(.system(size: 22, weight: .bold, design: .default))
                    Spacer()
                    PetDoodle(animal: .bird).frame(width: 38, height: 38)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .bottom) {
                        Text(L10n.text("和它一起，\n认识新朋友。"))
                            .font(.system(size: 33, weight: .semibold))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        PetDoodle(animal: .cat).frame(width: 106, height: 120)
                    }
                    Text(L10n.text("宠物交友、安心寄养和每一天的成长记录。"))
                        .font(.subheadline)
                        .foregroundStyle(PetTheme.secondaryInk)
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        accountMode(L10n.text("登录"), registration: false)
                        accountMode(L10n.text("注册"), registration: true)
                    }
                    .padding(4)
                    .background(PetTheme.surface, in: Capsule())
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(L10n.text("账号方式"))

                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel(L10n.text("邮箱"))
                        TextField(L10n.text("邮箱"), text: $draft.email, prompt: Text(L10n.text("请输入邮箱")).foregroundStyle(PetTheme.secondaryInk))
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .padding(16)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(PetTheme.border, lineWidth: 1))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(focusedField == .email ? PetTheme.ink : .clear, lineWidth: 1))
                            .accessibilityLabel(L10n.text("邮箱"))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel(L10n.text("密码"))
                        SecureField(L10n.text("密码"), text: $draft.password, prompt: Text(L10n.text("至少 8 位密码")).foregroundStyle(PetTheme.secondaryInk))
                            .textContentType(draft.isRegistration ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { if canSubmit { handleSignIn() } }
                            .padding(16)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(PetTheme.border, lineWidth: 1))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(focusedField == .password ? PetTheme.ink : .clear, lineWidth: 1))
                            .accessibilityLabel(L10n.text("密码"))
                    }

                    if draft.isRegistration {
                        PetTextField(title: L10n.text("你的昵称"), text: $draft.displayName, prompt: L10n.text("怎么称呼你"))
                        PetTextField(title: L10n.text("手机号"), text: $draft.phone, prompt: L10n.text("选填"))
                        PetTextField(title: L10n.text("所在城市"), text: $draft.city, prompt: L10n.text("例如：上海"))
                    }

                    Button(action: handleSignIn) {
                        HStack(spacing: 10) {
                            if appModel.isBusy { ProgressView().tint(.white) }
                            Text(draft.isRegistration ? L10n.text("注册 PetLife") : L10n.text("登录 PetLife"))
                        }
                    }
                    .buttonStyle(PetPrimaryButtonStyle())
                    .disabled(!canSubmit)

                    Text(draft.isRegistration ? L10n.text("注册后，请按邮件提示完成邮箱确认。") : L10n.text("欢迎回来，你和它的日常都在这里。"))
                        .font(.footnote)
                        .foregroundStyle(PetTheme.secondaryInk)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PetTheme.softBackground)
        .foregroundStyle(PetTheme.ink)
    }

    private var canSubmit: Bool {
        draft.email.contains("@") && draft.password.count >= 8 && !appModel.isBusy
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(L10n.text(text)).font(.subheadline.weight(.medium))
    }

    private func accountMode(_ label: String, registration: Bool) -> some View {
        let selected = draft.isRegistration == registration
        return Button {
            draft.isRegistration = registration
        } label: {
            Text(L10n.text(label))
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(selected ? PetTheme.ink : PetTheme.secondaryInk)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(selected ? PetTheme.ink : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func handleSignIn() {
        focusedField = nil
        Task { await appModel.signIn(draft) }
    }
}

private struct PetTextField: View {
    @Environment(\.locale) private var appLocale
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(title)).font(.subheadline.weight(.medium))
            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(PetTheme.border, lineWidth: 1))
                .accessibilityLabel(title)
        }
    }
}

#Preview {
    AuthenticationView(appModel: AppModel())
}
