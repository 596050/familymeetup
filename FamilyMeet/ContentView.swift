import SwiftUI
import UIKit

enum SwipeDirection { case left, right }

// Local profile captured during onboarding. Stored in UserDefaults as JSON.
struct UserProfile: Codable, Equatable {
    var names: String
    var city: String
    var kids: String
    var interests: String
}

struct Profile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let city: String
    let kids: String
    let color: Color
}

struct SwipeCard<Content: View>: View {
    let content: Content
    let onSwipe: (SwipeDirection) -> Void
    @State private var offset: CGSize = .zero

    init(@ViewBuilder content: () -> Content, onSwipe: @escaping (SwipeDirection) -> Void) {
        self.content = content()
        self.onSwipe = onSwipe
    }

    var body: some View {
        content
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 15)))
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { end in
                        let like = end.translation.width > 120
                        let pass = end.translation.width < -120
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if like {
                                offset = .init(width: 1200, height: 0)
                                onSwipe(.right)
                            } else if pass {
                                offset = .init(width: -1200, height: 0)
                                onSwipe(.left)
                            } else {
                                offset = .zero
                            }
                        }
                    }
            )
    }
}

struct ContentView: View {
    // Onboarding state stored across launches
    @AppStorage("fm_hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("fm_profile") private var profileJSON: String = ""

    @State private var showSettingsSheet = false
    @State private var showFiltersSheet = false
    @State private var showProfileSheet = false
    @State private var profiles: [Profile] = [
        .init(name: "Alex & Jamie", city: "Berkeley", kids: "2 and 5", color: .pink),
        .init(name: "Taylor & Sam", city: "Oakland", kids: "3", color: .orange),
        .init(name: "Riley", city: "San Francisco", kids: "1 and 4", color: .blue),
        .init(name: "Morgan", city: "Alameda", kids: "2", color: .green),
    ]
    #if DEBUG
        @State private var didApplyAppState = false
    #endif

    var body: some View {
        ZStack {
            if !hasOnboarded {
                OnboardingView(initial: loadProfile()) { profile in
                    saveProfile(profile)
                    withAnimation(.easeInOut) { hasOnboarded = true }
                }
                .id(profileJSON)
            } else {
                ZStack(alignment: .top) {
                    GeometryReader { geo in
                        ZStack {
                            ForEach(Array(profiles.enumerated()), id: \.element.id) { _, profile in
                                cardView(for: profile, size: geo.size)
                                    .allowsHitTesting(profile == profiles.last)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .ignoresSafeArea() // ensure cards extend under status and home areas
                    topBar
                }
                .sheet(isPresented: $showSettingsSheet) { settingsSheet }
                .sheet(isPresented: $showFiltersSheet) { filtersSheet }
                .fullScreenCover(isPresented: $showProfileSheet) { profileSheet }
            }
        }
        #if DEBUG
            .onAppear(perform: applyTestingStateIfAvailable)
        #endif
    }

    private var topBar: some View {
        FMTopBar {
            Button {
                showFiltersSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .buttonStyle(FMIconButtonStyle(variant: .tinted, size: .medium))
        } title: {
            Text("FamilyMeet").font(.headline.weight(.semibold)).foregroundStyle(.secondary)
        } trailing: {
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(FMIconButtonStyle(variant: .tinted, size: .medium))
        }
    }

    // Removed footer (X/Heart buttons) to keep swipe-only interactions

    private func isTop(_ index: Int) -> Bool { index == profiles.indices.last }

    private func swipeTop(_ dir: SwipeDirection) {
        guard let last = profiles.last else { return }
        handleSwipe(dir, profile: last)
    }

    private func handleSwipe(_ dir: SwipeDirection, profile: Profile) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            _ = profiles.popLast()
        }
        // Later: write swipe to backend and check for match
        // print("Swiped", dir, profile.name)
    }

    @ViewBuilder
    private func cardView(for profile: Profile, size: CGSize) -> some View {
        SwipeCard {
            FMFullScreenCard(color: profile.color) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name).font(.title.bold())
                    Text("\(profile.city) • kids: \(profile.kids)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } onSwipe: { dir in
            handleSwipe(dir, profile: profile)
        }
    }

    private func cardScale(for index: Int) -> CGFloat { 1.0 }

    private func cardOffsetY(for index: Int) -> CGFloat { 0 }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Onboarding

extension ContentView {
    #if DEBUG
        private func applyTestingStateIfAvailable() {
            guard !didApplyAppState, let state = AppStateLoader.loadState() else { return }
            didApplyAppState = true
            if let ob = state.onboarding {
                let profile = UserProfile(
                    names: ob.names, city: ob.city, kids: ob.kids, interests: ob.interests)
                saveProfile(profile)
                hasOnboarded = ob.hasOnboarded
            }
            if let p = state.profiles {
                profiles = p.map {
                    Profile(
                        name: $0.name, city: $0.city, kids: $0.kids,
                        color: AppStateLoader.color(from: $0.color))
                }
            }
        }
    #endif
    private var settingsSheet: some View {
        FMModalContainer(title: "Settings", onClose: { showSettingsSheet = false }) {
            FMMenuRow(title: "Profile", systemImage: "person.crop.circle") {
                // Dismiss settings, then present onboarding full-screen
                showSettingsSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showProfileSheet = true
                }
            }
        }
    }

    private var filtersSheet: some View {
        FMModalContainer(title: "Filters", onClose: { showFiltersSheet = false }) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Discovery filters coming soon.")
                Text("You’ll set distance, age ranges, and interests.")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical)
        }
    }

    private var profileSheet: some View {
        // Reuse the same onboarding flow to edit profile
        OnboardingView(
            initial: loadProfile(), startAtStep: 1, showClose: true,
            onClose: { showProfileSheet = false }
        ) { profile in
            saveProfile(profile)
            hasOnboarded = true
            showProfileSheet = false
        }
    }

    @ViewBuilder
    private func labeledRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func saveProfile(_ profile: UserProfile) {
        let enc = JSONEncoder()
        if let data = try? enc.encode(profile) {
            profileJSON = String(decoding: data, as: UTF8.self)
        }
    }

    private func loadProfile() -> UserProfile? {
        guard !profileJSON.isEmpty, let data = profileJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }
}

struct OnboardingView: View {
    var initial: UserProfile?
    var startAtStep: Int
    var showClose: Bool
    var onClose: (() -> Void)?
    var onComplete: (UserProfile) -> Void

    @State private var step: Int = 0
    @State private var confirmedAdult: Bool = false
    @State private var names: String = ""
    @State private var city: String = ""
    @State private var kids: String = ""
    @State private var interests: String = ""
    @State private var interestsSelection: Set<String> = []
    private let interestOptions = [
        "Playdates", "Parks", "Hiking", "Museums", "Coffee", "Library", "Sports",
    ]
    @StateObject private var keyboard = KeyboardObserver()
    @State private var toast: FMToastItem? = nil
    @FocusState private var focusedField: OnboardingField?
    @AppStorage("fm_profile") private var fmProfileJSON: String = ""

    enum OnboardingField: Hashable { case names, city, kids, interests }

    init(
        initial: UserProfile? = nil,
        startAtStep: Int = 0,
        showClose: Bool = false,
        onClose: (() -> Void)? = nil,
        onComplete: @escaping (UserProfile) -> Void
    ) {
        self.initial = initial
        self.startAtStep = startAtStep
        self.showClose = showClose
        self.onClose = onClose
        self.onComplete = onComplete
        _step = State(initialValue: startAtStep)
        if let initial {
            _names = State(initialValue: initial.names)
            _city = State(initialValue: initial.city)
            _kids = State(initialValue: initial.kids)
            _interests = State(initialValue: initial.interests)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                welcomeStep
                    .tag(0)
                infoStep
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            FMBottomBar(keyboardAware: true) { bottomBar }
        }
        .safeAreaInset(edge: .top) {
            if showClose {
                FMTopBar {
                    EmptyView()
                } title: {
                    EmptyView()
                } trailing: {
                    Button(action: { onClose?() }) { Image(systemName: "xmark") }
                        .buttonStyle(FMIconButtonStyle(variant: .tinted, size: .medium))
                }
            }
        }
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
        )
        .animation(.default, value: step)
        .onChange(of: step) { value in
            if value == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .names
                }
            }
        }
        .onAppear {
            // Prefill from initial if provided and local fields are empty
            guard let initial else { return }
            if names.isEmpty { names = initial.names }
            if city.isEmpty { city = initial.city }
            if kids.isEmpty { kids = initial.kids }
            if interests.isEmpty { interests = initial.interests }
        }
        .onChange(of: initial) { newVal in
            guard let i = newVal else { return }
            if names.isEmpty { names = i.names }
            if city.isEmpty { city = i.city }
            if kids.isEmpty { kids = i.kids }
            if interests.isEmpty { interests = i.interests }
        }
        .onAppear { applyFromStoredProfile() }
        .onChange(of: fmProfileJSON) { _ in applyFromStoredProfile() }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            Text("Welcome to FamilyMeet")
                .font(.largeTitle).fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text("Meet nearby families with simple, safe swipes.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                labelRow(system: "hand.thumbsup.fill", text: "Swipe to like or pass")
                labelRow(system: "message.fill", text: "Match and start a chat")
                labelRow(system: "mappin.and.ellipse", text: "Use city/region, not exact location")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Toggle(isOn: $confirmedAdult) {
                Text("I confirm I am 18+")
            }
            .toggleStyle(.switch)
            .padding(.horizontal)
            .accessibilityIdentifier("onboarding.adultToggle")

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if ProcessInfo.processInfo.environment["FM_AUTO_ADVANCE"] == "1" {
                confirmedAdult = true
                step = 1
            }
        }
    }

    private var infoStep: some View {
        FMFocusableScrollContainer(
            focused: Binding(get: { focusedField }, set: { focusedField = $0 }), bottomExtra: 220
        ) {
            VStack(spacing: 16) {
                Group {
                    FMTextField(
                        "Parent names (optional)",
                        text: $names,
                        placeholder: "e.g., Alex & Jamie",
                        systemImage: "person.2",
                        id: "onboarding.names",
                        submitLabel: .next,
                        onSubmit: { focusedField = .city }
                    )
                    .id(OnboardingField.names)
                    .focused($focusedField, equals: .names)

                    FMTextField(
                        "City or neighborhood",
                        text: $city,
                        placeholder: "e.g., Berkeley",
                        systemImage: "mappin.and.ellipse",
                        id: "onboarding.city",
                        textContentType: .addressCity,
                        autocapitalization: .words,
                        submitLabel: .next,
                        onSubmit: { focusedField = .kids }
                    )
                    .id(OnboardingField.city)
                    .focused($focusedField, equals: .city)

                    FMTextField(
                        "Kids ages",
                        text: $kids,
                        placeholder: "e.g., 2 and 5",
                        systemImage: "figure.2.and.child.holdinghands",
                        id: "onboarding.kids",
                        submitLabel: .next,
                        onSubmit: { focusedField = .interests }
                    )
                    .id(OnboardingField.kids)
                    .focused($focusedField, equals: .kids)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests").font(.headline)
                    FMChipGroup(
                        options: interestOptions, selection: $interestsSelection,
                        allowsMultipleSelection: true)
                    FMTextField(
                        "Other interests",
                        text: $interests,
                        placeholder: "comma separated",
                        systemImage: "tag",
                        id: "onboarding.interestsText",
                        submitLabel: .done,
                        onSubmit: { focusedField = nil }
                    )
                    .id(OnboardingField.interests)
                    .focused($focusedField, equals: .interests)
                }
                Text("You can edit this later from Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Ensure fields prefill from either passed initial or saved defaults
            if let i = initial {
                names = i.names
                city = i.city
                kids = i.kids
                interests = i.interests
            } else if let saved = loadSavedProfile() {
                names = saved.names
                city = saved.city
                kids = saved.kids
                interests = saved.interests
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedField = .names }
        }
        .fmToast(item: $toast)
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Review").font(.title2.bold())
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Names")
                        Spacer()
                        Text(names.isEmpty ? "—" : names).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("City")
                        Spacer()
                        Text(city.isEmpty ? "—" : city).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Kids")
                        Spacer()
                        Text(kids.isEmpty ? "—" : kids).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Interests")
                        Spacer()
                        Text(interests.isEmpty ? "—" : interests).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
            .padding(.bottom, 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .scrollDismissesKeyboard(.interactively)
    }

    private var bottomBar: some View {
        HStack {
            if step > 0 {
                Button("Back") { step = max(0, step - 1) }
            }
            Spacer()
            if step < 2 {
                Button("Continue") {
                    if step == 0 {
                        guard confirmedAdult else { return }
                        step += 1
                        return
                    }
                    // Validate city on info step
                    if step == 1 && city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        toast = FMToastItem(
                            message: "Please enter your city or neighborhood.", style: .warning)
                        return
                    }
                    step += 1
                }
                .fmButton(.primary)
                .accessibilityIdentifier("onboarding.continue")
                .disabled(step == 0 && !confirmedAdult)
            } else {
                Button("Finish") {
                    let combinedInterests: String = {
                        let chips = Array(interestsSelection).sorted()
                        let free = interests
                        let parts = (chips + (free.isEmpty ? [] : [free]))
                        return parts.joined(separator: ", ")
                    }()
                    let profile = UserProfile(
                        names: names.trimmingCharacters(in: .whitespacesAndNewlines),
                        city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                        kids: kids.trimmingCharacters(in: .whitespacesAndNewlines),
                        interests: combinedInterests)
                    onComplete(profile)
                }
                .fmButton(.success)
            }
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder
    private func labelRow(system: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: system)
                .foregroundStyle(.tint)
            Text(text)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadSavedProfile() -> UserProfile? {
        if let json = UserDefaults.standard.string(forKey: "fm_profile"),
            let data = json.data(using: .utf8),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        {
            return profile
        }
        return nil
    }

    private func applyFromStoredProfile() {
        guard !fmProfileJSON.isEmpty, let data = fmProfileJSON.data(using: .utf8),
            let p = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return }
        names = p.names
        city = p.city
        kids = p.kids
        interests = p.interests
    }
}

// KeyboardObserver moved to DesignSystem/Utilities/Keyboard.swift
