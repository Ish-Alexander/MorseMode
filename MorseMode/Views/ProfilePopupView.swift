//
//  ProfilePopupView.swift
//  MorseMode
//
//  Created by Wisdom Ogwonuwe on 4/21/26.
//

import SwiftUI
import PhotosUI
import Combine
import AVFoundation

enum DifficultyLevel: String, CaseIterable, Codable {
    case easy   = "EASY"
    case normal = "NORMAL"
    case hard   = "HARD"

    var speedMultiplier: Double {
        switch self { case .easy: return 0.50; case .normal: return 1.00; case .hard: return 2.00 }
    }
    var hintsAllowed: Int {
        switch self { case .easy: return 3; case .normal: return 1; case .hard: return 0 }
    }
    var subtitle: String {
        switch self {
        case .easy:   return "Half speed"
        case .normal: return "Standard"
        case .hard:   return "2x speed"
        }
    }
    var icon: String {
        switch self { case .easy: return "tortoise.fill"; case .normal: return "hare.fill"; case .hard: return "bolt.fill" }
    }
}

struct ProfileExtras: Codable {
    var codename: String            = "Agent Zero"
    var avatarIndex: Int            = -1
    var difficulty: DifficultyLevel = .normal
    var notificationsEnabled: Bool  = true

    static func load() -> ProfileExtras {
        guard let data = UserDefaults.standard.data(forKey: "profileExtras"),
              let decoded = try? JSONDecoder().decode(ProfileExtras.self, from: data)
        else { return ProfileExtras() }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "profileExtras")
        }
    }
}

let presetAvatarSymbols: [String] = [
    "bolt.shield.fill",
    "antenna.radiowaves.left.and.right",
    "lock.shield.fill",
    "eye.slash.fill",
    "waveform",
    "cpu.fill",
    "network",
    "dot.radiowaves.left.and.right"
]

private let journeyLevelCount = 15

func rankName(for level: Int) -> String {
    switch level {
    case 1...2:   return "Field Operative"
    case 3...4:   return "Signal Analyst"
    case 5...8:   return "Cipher Agent"
    case 9...10: return "Shadow Operative"
    default:      return "Ghost Protocol"
    }
}

struct ProfileXPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let fillWidth = max(42, width * fraction)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.09, green: 0.21, blue: 0.31).opacity(0.96))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.neon.opacity(0.32), lineWidth: 2))

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.neon)
                    .frame(width: fillWidth)

                HStack(spacing: 5) {
                    ForEach(0..<10, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color(red: 0.20, green: 0.33, blue: 0.45), lineWidth: 1)
                            .frame(height: 22)
                            .opacity(i < Int((fraction * 10).rounded(.down)) ? 0 : 1)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .frame(height: 34)
    }
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.neon)
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.custom("berkelium bitmap", size: 9))
                .foregroundStyle(Color.white.opacity(0.45)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.neon.opacity(0.38), lineWidth: 1.8)))
    }
}

struct AgentToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.neon).frame(width: 22)
            Text(label).font(.custom("berkelium bitmap", size: 14)).foregroundStyle(.white)
            Spacer()
            ZStack {
                Capsule()
                    .fill(isOn ? Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.9)
                               : Color(red: 0.06, green: 0.13, blue: 0.18))
                    .overlay(Capsule().stroke(isOn ? Color.neon : Color.white.opacity(0.2), lineWidth: 1.8))
                    .frame(width: 48, height: 26)
                Circle().fill(isOn ? Color.neon : Color.white.opacity(0.35))
                    .frame(width: 20, height: 20)
                    .shadow(color: isOn ? Color.neon.opacity(0.7) : .clear, radius: 5)
                    .offset(x: isOn ? 11 : -11)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isOn)
            }.onTapGesture { isOn.toggle() }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.neon.opacity(0.3), lineWidth: 1.8)))
    }
}

struct AvatarPickerSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var store: AvatarStore
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.09, blue: 0.14).ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    ZStack {
                        Image("Header").resizable().scaledToFit().frame(maxWidth: 260).opacity(0.9)
                        Text("Select Avatar").font(.custom("berkelium bitmap", size: 16))
                            .foregroundStyle(.white).padding(.bottom, 4)
                    }
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white).padding(10)
                            .background(Circle().fill(Color(red: 0.08, green: 0.17, blue: 0.24))
                                .overlay(Circle().stroke(Color.neon.opacity(0.5), lineWidth: 1.5)))
                    }
                }.padding(.horizontal, 20).padding(.top, 16)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.neon)
                        Text("Choose from Photo Library")
                            .font(.custom("berkelium bitmap", size: 14)).foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.neon, lineWidth: 1.8)))
                }
                .padding(.horizontal, 20)
                .onChange(of: photoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            await MainActor.run {
                                store.save(index: -1, image: img)
                                isPresented = false
                            }
                        }
                    }
                }

                Text("— or choose an agent icon —")
                    .font(.custom("berkelium bitmap", size: 10)).foregroundStyle(Color.white.opacity(0.4))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                    ForEach(presetAvatarSymbols.indices, id: \.self) { i in
                        let active = store.avatarIndex == i && store.customAvatar == nil
                        ZStack {
                            Circle()
                                .fill(active ? Color.neon.opacity(0.18) : Color(red: 0.08, green: 0.17, blue: 0.24))
                                .overlay(Circle().stroke(active ? Color.neon : Color.neon.opacity(0.3),
                                    lineWidth: active ? 2.8 : 1.4))
                                .frame(width: 66, height: 66)
                            Image(systemName: presetAvatarSymbols[i])
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(active ? Color.neon : Color.white.opacity(0.65))
                        }
                        .onTapGesture {
                            store.save(index: i, image: nil)
                            isPresented = false
                        }
                    }
                }.padding(.horizontal, 20)
                Spacer()
            }
        }.preferredColorScheme(.dark)
    }
}

struct ProfileAvatarCircle: View {
    let size: CGFloat
    @ObservedObject var store: AvatarStore

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [Color(red: 0.97, green: 0.23, blue: 0.20),
                         Color(red: 1.0, green: 0.88, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color.neon, lineWidth: 3.5).padding(1)
            if let img = store.customAvatar {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: size - 8, height: size - 8).clipShape(Circle())
            } else if store.avatarIndex >= 0, store.avatarIndex < presetAvatarSymbols.count {
                Image(systemName: presetAvatarSymbols[store.avatarIndex])
                    .font(.system(size: size * 0.35, weight: .semibold)).foregroundStyle(.white)
            } else {
                Image("Icon").resizable().scaledToFit().padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.neon.opacity(0.3), radius: 8)
    }
}

struct ProfilePopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var avatarStore: AvatarStore = AvatarStore.shared

    #if os(iOS)
    @EnvironmentObject private var userProgress: UserProgress
    #endif

    enum Tab: String, CaseIterable { case stats = "STATS"; case settings = "SETTINGS" }

    @State private var extras: ProfileExtras = ProfileExtras.load()
    @State private var selectedTab: Tab = .stats
    @State private var showAvatarPicker = false
    @State private var isEditingCodename = false
    @State private var editedCodename = ""
    @FocusState private var codenameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
                .onTapGesture { withAnimation { isPresented = false } }

            VStack(spacing: 0) {
                headerSection
                tabBar.padding(.top, 2)
                Group {
                    if selectedTab == .stats {
                        ScrollView(showsIndicators: false) { statsContent.padding(16) }
                    } else {
                        ScrollView(showsIndicators: false) { settingsContent.padding(16) }
                    }
                }
                .frame(height: 300)
                .animation(.easeInOut(duration: 0.18), value: selectedTab)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.09, blue: 0.14))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.5))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.neon, lineWidth: 2.8)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1).padding(6)
                }
            )
            .shadow(color: Color.neon.opacity(0.18), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)

        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isPresented)
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(isPresented: $showAvatarPicker, store: avatarStore)
                .presentationDetents([.medium, .large])
        }
        .onAppear { editedCodename = extras.codename }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 22) {
            Button { showAvatarPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatarCircle(size: 70, store: avatarStore)
                    Image(systemName: "pencil.circle.fill").font(.system(size: 20))
                        .foregroundStyle(Color.neon)
                        .background(Circle().fill(Color(red: 0.04, green: 0.09, blue: 0.14)).padding(2))
                        .offset(x: 4, y: 4)
                }
            }.buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                if isEditingCodename {
                    HStack(spacing: 6) {
                        TextField("CODENAME", text: $editedCodename)
                            .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .focused($codenameFieldFocused)
                            .onSubmit { commitCodename() }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.09, green: 0.21, blue: 0.31).opacity(0.96))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.neon.opacity(0.7), lineWidth: 1.8)))
                        Button { commitCodename() } label: {
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.neon)
                        }
                    }
                    .onAppear { codenameFieldFocused = true }
                } else {
                    Button {
                        editedCodename = extras.codename
                        isEditingCodename = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(extras.codename.uppercased())
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Image(systemName: "pencil.circle.fill").font(.system(size: 20))
                                .foregroundStyle(Color.neon)
                                .background(Circle().fill(Color(red: 0.04, green: 0.09, blue: 0.14)).padding(2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain)
                }
                Text("Tap rank card for full profile")
                    .font(.custom("berkelium bitmap", size: 10)).foregroundStyle(Color.neon.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 0)

            Button { withAnimation { isPresented = false } } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white).padding(10)
                    .background(Circle().fill(Color(red: 0.08, green: 0.17, blue: 0.24))
                        .overlay(Circle().stroke(Color.neon.opacity(0.45), lineWidth: 1.5)))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } } label: {
                    VStack(spacing: 5) {
                        Text(tab.rawValue).font(.custom("berkelium bitmap", size: 13))
                            .foregroundStyle(selectedTab == tab ? Color.neon : Color.white)
                        Rectangle().fill(selectedTab == tab ? Color.neon : Color.clear).frame(height: 2.2)
                            .shadow(color: selectedTab == tab ? Color.neon.opacity(0.6) : .clear, radius: 4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
        .background(Rectangle().fill(Color.neon.opacity(0.08)).frame(height: 1), alignment: .bottom)
        .padding(.horizontal, 10)
    }

    private var statsContent: some View {
        VStack(spacing: 10) {
            #if os(iOS)
            let xpFrac = min(Double(userProgress.currentEXP) / Double(max(userProgress.expNeededForNextLevel, 1)), 1)

            VStack(spacing: 6) {
                HStack {
                    Text(extras.codename.uppercased())
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("LVL \(userProgress.level)")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(Color.neon)
                }
                ProfileXPBar(fraction: xpFrac)
                HStack(alignment: .top) {
                    Text("\(userProgress.currentEXP) / \(userProgress.expNeededForNextLevel) XP")
                        .font(.custom("berkelium bitmap", size: 9))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    Text("Rank: \(rankName(for: userProgress.level))")
                        .font(.custom("berkelium bitmap", size: 9))
                        .foregroundStyle(Color.neon.opacity(0.7))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.neon.opacity(0.38), lineWidth: 1.8)))

            HStack(spacing: 10) {
                statBadge(icon: "target",             value: "\(userProgress.completedLevels.count)", label: "MISSIONS")
                statBadge(icon: "checkmark.seal.fill", value: "\(userProgress.completedLevels.count)/\(journeyLevelCount)", label: "JOURNEY")
                statBadge(icon: "slider.horizontal.3", value: extras.difficulty.rawValue,            label: "MODE")
            }
            #else
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.fill").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.neon).padding(.top, 1)
                Text("CODENAME: \(extras.codename.uppercased())")
                    .font(.custom("berkelium bitmap", size: 12)).foregroundStyle(.white)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.neon.opacity(0.38), lineWidth: 1.8)))
            #endif
        }
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(Color.neon)
            Text(value).font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.custom("berkelium bitmap", size: 8)).foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.neon.opacity(0.3), lineWidth: 1.5)))
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.neon).frame(width: 22)
                Text("DIFFICULTY").font(.custom("berkelium bitmap", size: 14)).foregroundStyle(.white)
            }
            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { diff in
                    let active = extras.difficulty == diff
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { extras.difficulty = diff }
                        extras.save()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: diff.icon).font(.system(size: 16, weight: .bold))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14) : Color.neon.opacity(0.55))
                            Text(diff.rawValue).font(.custom("berkelium bitmap", size: 11))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14) : Color.white.opacity(0.5))
                            Text(diff.subtitle).font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14).opacity(0.7) : Color.white.opacity(0.28))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 11).padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(active ? Color.neon : Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.7))
                            .shadow(color: active ? Color.neon.opacity(0.45) : .clear, radius: 7))
                    }.buttonStyle(.plain)
                }
            }

            Button {
                editedCodename = extras.codename
                isEditingCodename = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.neon)
                        .frame(width: 22)
                    Text("Change Codename")
                        .font(.custom("berkelium bitmap", size: 14))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.38))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.09, blue: 0.14).opacity(0.74))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.neon.opacity(0.25), lineWidth: 1.4)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.neon.opacity(0.3), lineWidth: 1.8)))
    }

    private func commitCodename() {
        let v = editedCodename.trimmingCharacters(in: .whitespacesAndNewlines)
        if !v.isEmpty { extras.codename = v }
        extras.save()
        isEditingCodename = false
        codenameFieldFocused = false
    }
}

#if os(iOS)
struct ProfileView: View {
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var morseEngine: MorseEngine
    @ObservedObject private var avatarStore = AvatarStore.shared

    @State private var extras: ProfileExtras = ProfileExtras.load()
    @State private var isStatsTab = true
    @State private var showAvatarPicker = false
    @State private var isEditingCodename = false
    @State private var editedCodename = ""
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var previewAudioPlayer: AVAudioPlayer?
    @FocusState private var codenameFieldFocused: Bool

    init(initiallyShowingSettings: Bool = false) {
        _isStatsTab = State(initialValue: !initiallyShowingSettings)
    }

    private var xpFraction: Double {
        min(Double(userProgress.currentEXP) / Double(max(userProgress.expNeededForNextLevel, 1)), 1)
    }

    private var isDigitalRainEnabled: Binding<Bool> {
        Binding(
            get: { playbackSettings.isDigitalRainEnabled },
            set: { playbackSettings.isDigitalRainEnabled = $0 }
        )
    }

    var body: some View {
        ZStack {
            DigitalRainBackground(isPaused: !playbackSettings.isDigitalRainEnabled)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    identityBlock.padding(.top, 12)
                    tabStrip
                    if isStatsTab { statsSection } else { settingsSection }
                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AGENT PROFILE")
                    .font(.custom("berkelium bitmap", size: 16))
                    .foregroundStyle(Color.neon)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.neon.opacity(0.38), lineWidth: 1.8)))
            }
        }
        .onAppear {
            extras = ProfileExtras.load()
            editedCodename = extras.codename
            soundEnabled   = playbackSettings.mode.allowsSound
            hapticsEnabled = playbackSettings.mode.allowsHaptics
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(isPresented: $showAvatarPicker, store: avatarStore)
                .presentationDetents([.medium, .large])
        }
        .preferredColorScheme(.dark)
    }

    private var identityBlock: some View {
        VStack(spacing: 22) {
            Button { showAvatarPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatarCircle(size: 94, store: avatarStore)
                    Image(systemName: "pencil.circle.fill").font(.system(size: 24))
                        .foregroundStyle(Color.neon)
                        .background(Circle().fill(Color(red: 0.04, green: 0.09, blue: 0.14)).padding(3))
                        .offset(x: 5, y: 5)
                }
            }.buttonStyle(.plain)

            if isEditingCodename {
                HStack(spacing: 8) {
                    TextField("CODENAME", text: $editedCodename)
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .multilineTextAlignment(.center).textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .focused($codenameFieldFocused)
                        .onSubmit { commitCodename() }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.09, green: 0.21, blue: 0.31).opacity(0.96))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.neon.opacity(0.7), lineWidth: 2)))
                    Button { commitCodename() } label: {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.neon)
                    }
                }
                .padding(.horizontal, 40)
                .onAppear { codenameFieldFocused = true }
            } else {
                Button {
                    editedCodename = extras.codename
                    isEditingCodename = true
                } label: {
                    HStack(spacing: 8) {
                        Text(extras.codename.uppercased())
                            .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        Image(systemName: "pencil.circle.fill").font(.system(size: 24))
                            .foregroundStyle(Color.neon)
                            .background(Circle().fill(Color(red: 0.04, green: 0.09, blue: 0.14)).padding(3))
                    }
                }.buttonStyle(.plain)
            }

            Text("Rank: \(rankName(for: userProgress.level))  •  LVL: \(userProgress.level)")
                .font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(Color.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                ProfileXPBar(fraction: xpFraction)
                Text("\(userProgress.currentEXP) / \(userProgress.expNeededForNextLevel) XP")
                    .font(.custom("berkelium bitmap", size: 10)).foregroundStyle(Color.white.opacity(0.4))
            }.padding(.horizontal, 32)
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 0) {
            ForEach([("STATS", true), ("SETTINGS", false)], id: \.0) { title, isStats in
                Button { withAnimation(.easeInOut(duration: 0.2)) { isStatsTab = isStats } } label: {
                    VStack(spacing: 5) {
                        Text(title).font(.custom("berkelium bitmap", size: 14))
                            .foregroundStyle(isStatsTab == isStats ? Color.neon : Color.white)
                        Rectangle().fill(isStatsTab == isStats ? Color.neon : Color.clear).frame(height: 2.2)
                            .shadow(color: isStatsTab == isStats ? Color.neon.opacity(0.6) : .clear, radius: 4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
        .background(Rectangle().fill(Color.neon.opacity(0.08)).frame(height: 1), alignment: .bottom)
        .padding(.horizontal, 24)
        .background(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.6))
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(icon: "target",
                         value: "\(userProgress.completedLevels.count)",
                         label: "MISSIONS")
                StatTile(icon: "checkmark.seal.fill",
                         value: "\(userProgress.completedLevels.count)/\(journeyLevelCount)",
                         label: "JOURNEY")
                StatTile(icon: "star.fill",
                         value: "LVL \(userProgress.level)",
                         label: "LEVEL")
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.neon).padding(.top, 1)
                Text("MISSION FOCUS: Complete Agent Journey to increase your skills and progress to Level \(userProgress.level + 1)!")
                    .font(.custom("berkelium bitmap", size: 11)).foregroundStyle(Color.white.opacity(0.8)).lineSpacing(3)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.neon.opacity(0.38), lineWidth: 1.8)))
        }.padding(.horizontal, 24)
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {

            difficultyPicker

            AgentToggleRow(label: "Sound Effects",       icon: "speaker.wave.2.fill", isOn: $soundEnabled)
                .onChange(of: soundEnabled) { _, enabled in
                    if enabled {
                        playSoundPreview()
                    }
                }
            AgentToggleRow(label: "Haptic Feedback",     icon: "hand.tap.fill",        isOn: $hapticsEnabled)
                .onChange(of: hapticsEnabled) { _, enabled in
                    if enabled {
                        morseEngine.performHaptic(for: .t)
                    }
                }
            AgentToggleRow(label: "Daily Notifications", icon: "bell.badge.fill",       isOn: $extras.notificationsEnabled)
                .onChange(of: extras.notificationsEnabled) { _, enabled in
                    Task {
                        let accepted = await DailyNotificationManager.shared.setDailyReminderEnabled(enabled)
                        await MainActor.run {
                            if enabled && !accepted {
                                extras.notificationsEnabled = false
                            }
                            extras.save()
                        }
                    }
                }
            AgentToggleRow(label: "Digital Rain",        icon: "eye",                  isOn: isDigitalRainEnabled)

        }.padding(.horizontal, 24)
    }

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.neon).frame(width: 22)
                Text("DIFFICULTY").font(.custom("berkelium bitmap", size: 14)).foregroundStyle(.white)
            }
            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { diff in
                    let active = extras.difficulty == diff
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { extras.difficulty = diff }
                        extras.save()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: diff.icon).font(.system(size: 16, weight: .bold))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14) : Color.neon.opacity(0.55))
                            Text(diff.rawValue).font(.custom("berkelium bitmap", size: 11))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14) : Color.white.opacity(0.5))
                            Text(diff.subtitle).font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(active ? Color(red: 0.04, green: 0.09, blue: 0.14).opacity(0.7) : Color.white.opacity(0.28))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 11).padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(active ? Color.neon : Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.7))
                            .shadow(color: active ? Color.neon.opacity(0.45) : .clear, radius: 7))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.neon.opacity(0.3), lineWidth: 1.8)))
    }

    private func commitCodename() {
        let v = editedCodename.trimmingCharacters(in: .whitespacesAndNewlines)
        if !v.isEmpty { extras.codename = v }
        extras.save()
        isEditingCodename = false
        codenameFieldFocused = false
    }

    private func playSoundPreview() {
        let playback = MorseLetterAudio.play(
            character: "T",
            reusing: previewAudioPlayer,
            logPrefix: "Profile"
        )
        previewAudioPlayer = playback.player
    }
}

#Preview("Profile Page") {
    NavigationStack {
        ProfileView()
            .environmentObject(UserProgress())
            .environmentObject(PlaybackSettings())
            .environmentObject(MorseEngine())
    }
    .preferredColorScheme(.dark)
}
#endif
