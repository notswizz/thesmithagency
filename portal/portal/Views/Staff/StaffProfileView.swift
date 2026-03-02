import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

struct StaffProfileView: View {
    let uid: String
    @Bindable var viewModel: StaffViewModel
    @Environment(AuthManager.self) private var authManager

    @State private var currentStep = 0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSavedAlert = false
    @State private var showDocumentPicker = false
    @State private var showDirectDeposit = false
    @State private var appearAnimation = false

    private let tabs: [(icon: String, label: String)] = [
        ("person.text.rectangle", "Contact"),
        ("ruler", "Sizing"),
        ("briefcase", "Experience"),
        ("doc.plaintext", "Forms"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        avatarSection
                        payRateBadge
                            .padding(.top, 8)
                        tabBar
                            .padding(.top, 20)
                        stepContent
                            .padding(.top, 20)
                        actionsSection
                            .padding(.top, 28)
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if viewModel.staff == nil {
                    await viewModel.loadStaff(uid: uid)
                }
            }
            .alert("Saved", isPresented: $showSavedAlert) {
                Button("OK") {}
            } message: {
                Text("Your profile has been updated.")
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.uploadHeadshot(uid: uid, image: image)
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { data, filename in
                    Task {
                        await viewModel.uploadResume(uid: uid, data: data, filename: filename)
                    }
                }
            }
            .sheet(isPresented: $showDirectDeposit) {
                DirectDepositFormView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView().tint(.brand)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                avatarImage
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 32, height: 32)
                            .shadow(color: .brand.opacity(0.4), radius: 6, y: 2)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                    }
                }
            }
            .scaleEffect(appearAnimation ? 1 : 0.85)
            .opacity(appearAnimation ? 1 : 0)

            if let name = viewModel.staff?.name, !name.isEmpty {
                Text(name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.textPrimary)
            }

            if let email = viewModel.staff?.email, !email.isEmpty {
                Text(email)
                    .font(.system(size: 13))
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let url = viewModel.staff?.photoURL, !url.isEmpty {
            AsyncImage(url: URL(string: url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.brand.opacity(0.3), lineWidth: 2))
        } else {
            avatarPlaceholder
                .overlay(Circle().strokeBorder(Color.borderSubtle))
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.surfaceCard)
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.textTertiary)
            )
    }

    // MARK: - Pay Rate

    @ViewBuilder
    private var payRateBadge: some View {
        if let staff = viewModel.staff, let rateStr = staff.payRate, let rate = Double(rateStr), rate > 0 {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.brand)
                Text("$\(Int(rate))/hr")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.brand)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.brand.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { i in
                let tab = tabs[i]
                let selected = currentStep == i

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentStep = i
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(selected ? Color.brand : Color.surfaceElevated)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle().strokeBorder(selected ? Color.brand : Color.borderSubtle)
                                )
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(selected ? .white : .textTertiary)
                        }
                        Text(tab.label.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(selected ? .brand : .textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 16) {
            switch currentStep {
            case 0: contactStep
            case 1: sizingStep
            case 2: experienceStep
            case 3: formsStep
            default: EmptyView()
            }
        }
        .padding(.horizontal, 20)
        .transition(.opacity)
    }

    // MARK: - Contact Step

    private var contactStep: some View {
        VStack(spacing: 16) {
            sectionCard(icon: "phone.fill", title: "PHONE & SOCIAL") {
                formField("Phone", text: $viewModel.phone, icon: "phone", keyboard: .phonePad)
                formField("Instagram", text: $viewModel.instagram, icon: "at")
            }

            sectionCard(icon: "mappin.circle.fill", title: "LOCATION") {
                HStack(spacing: 8) {
                    ForEach(AppConstants.locations, id: \.self) { city in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.location = city
                            }
                        } label: {
                            Text(city)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(viewModel.location == city ? Color.brand : Color.surfaceElevated)
                                .foregroundStyle(viewModel.location == city ? .white : .textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(viewModel.location == city ? Color.brand : Color.borderSubtle)
                                )
                        }
                    }
                }
                AddressSearchField(label: "Address", text: $viewModel.address)
            }

            sectionCard(icon: "building.columns.fill", title: "EDUCATION") {
                formField("College", text: $viewModel.college, icon: "graduationcap")
            }
        }
    }

    // MARK: - Sizing Step

    private var sizingStep: some View {
        sectionCard(icon: "ruler.fill", title: "SIZING") {
            formField("Dress Size", text: $viewModel.dressSize, icon: "tshirt")
            formField("Shoe Size", text: $viewModel.shoeSize, icon: "shoe")
        }
    }

    // MARK: - Experience Step

    private var experienceStep: some View {
        sectionCard(icon: "briefcase.fill", title: "RETAIL/WHOLESALE EXPERIENCE") {
            TextEditor(text: $viewModel.experience)
                .font(.system(size: 15))
                .foregroundStyle(.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .padding(14)
                .background(Color.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    Group {
                        if viewModel.experience.isEmpty {
                            Text("Describe your retail and wholesale experience...")
                                .font(.system(size: 15))
                                .foregroundStyle(.textTertiary.opacity(0.5))
                                .padding(.leading, 18)
                                .padding(.top, 22)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }

    // MARK: - Forms Step

    private var formsStep: some View {
        let hasResume = viewModel.staff?.resumeURL != nil && !(viewModel.staff?.resumeURL ?? "").isEmpty
        let hasDeposit = viewModel.staff?.directDepositCompleted == true

        return VStack(spacing: 12) {
            formRowCard(
                icon: "doc.text.fill",
                title: "Resume",
                subtitle: hasResume ? "Uploaded" : "Not uploaded",
                completed: hasResume,
                actionLabel: hasResume ? "Replace" : "Upload"
            ) {
                showDocumentPicker = true
            }

            formRowCard(
                icon: "banknote.fill",
                title: "Direct Deposit",
                subtitle: hasDeposit ? "Completed" : "Not submitted",
                completed: hasDeposit,
                actionLabel: hasDeposit ? "Edit" : "Enter"
            ) {
                showDirectDeposit = true
            }

            formRowCard(
                icon: "signature",
                title: "Contract",
                subtitle: "Coming soon",
                completed: false,
                locked: true
            )
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.hasChanges {
                Button {
                    Task {
                        await viewModel.saveProfile()
                        showSavedAlert = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(.brand)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                authManager.signOut()
            } label: {
                Text("Sign Out")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brand)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.textTertiary)
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
    }

    // MARK: - Form Field

    private func formField(
        _ placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
                .frame(width: 18)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.textTertiary.opacity(0.7)))
                .font(.system(size: 15))
                .foregroundStyle(.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Form Row Card

    private func formRowCard(
        icon: String,
        title: String,
        subtitle: String,
        completed: Bool,
        actionLabel: String = "",
        locked: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(completed ? Color.green.opacity(0.12) : Color.brand.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: completed ? "checkmark.circle.fill" : icon)
                        .font(.system(size: 18))
                        .foregroundStyle(completed ? .green : .brand)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(completed ? .green : .textTertiary)
                }

                Spacer()

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.textTertiary.opacity(0.4))
                } else {
                    HStack(spacing: 4) {
                        Text(actionLabel)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.brand)
                }
            }
            .padding(16)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.borderSubtle))
        }
        .disabled(locked)
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (Data, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .data])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data, String) -> Void
        init(onPick: @escaping (Data, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first,
                  url.startAccessingSecurityScopedResource(),
                  let data = try? Data(contentsOf: url) else { return }
            url.stopAccessingSecurityScopedResource()
            onPick(data, url.lastPathComponent)
        }
    }
}
