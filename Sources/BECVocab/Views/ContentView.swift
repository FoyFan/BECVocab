import SwiftUI

struct ContentView: View {
    @Environment(DataService.self) private var dataService
    @Environment(SpeechService.self) private var speechService
    @State private var sidebarCollapsed = false
    @State private var mouseLocation = CGPoint.zero

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Sidebar
                if !sidebarCollapsed {
                    WordListView()
                        .frame(width: 240)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Card area
                WordCardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .topLeading) {
                // Toggle sidebar button
                Button(action: { withAnimation(.easeInOut(duration: 0.25)) { sidebarCollapsed.toggle() } }) {
                    Image(systemName: sidebarCollapsed ? "chevron.right" : "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                        .frame(width: 22, height: 22)
                        .background(.ultraThinMaterial.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .offset(x: sidebarCollapsed ? 8 : 248, y: 48)
                .animation(.easeInOut(duration: 0.25), value: sidebarCollapsed)
            }
            .background {
                RainbowBackground()
            }
            .overlay(alignment: .top) {
                TopBarView(sidebarCollapsed: $sidebarCollapsed)
                    .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyEvent(event)
                return event
            }
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        switch event.keyCode {
        case 49: // Space
            if let word = dataService.currentWord {
                speechService.speak(word.en)
            }
        case 123, 126: // Left arrow, Up arrow
            dataService.goPrevious()
            if let word = dataService.currentWord {
                speechService.speak(word.en)
            }
        case 124, 125: // Right arrow, Down arrow
            dataService.goNext()
            if let word = dataService.currentWord {
                speechService.speak(word.en)
            }
        case 36: // Enter
            dataService.goNext()
            if let word = dataService.currentWord {
                speechService.speak(word.en)
            }
        default:
            break
        }
    }
}

// MARK: - Rainbow Background
struct RainbowBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.0, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.08, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.17, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.33, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.5, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.67, saturation: 0.8, brightness: 0.5),
                Color(hue: 0.83, saturation: 0.8, brightness: 0.5),
                Color(hue: 1.0, saturation: 0.8, brightness: 0.5),
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .opacity(0.35)
        .animation(.linear(duration: 30).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
        .overlay(
            RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 100, endRadius: 600)
        )
    }
}

// MARK: - Top Bar
struct TopBarView: View {
    @Environment(DataService.self) private var dataService
    @Environment(SpeechService.self) private var speechService
    @Binding var sidebarCollapsed: Bool
    @State private var showSearch = false
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 12) {
            Text("BEC词汇")
                .font(.custom("Georgia", size: 16))
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text("商务英语")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
            Text("foy.fan@outlook.com")
                .font(.system(size: 9))
                .foregroundColor(.tertiary)
                .padding(.leading, 4)

            Spacer()

            // Search
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("搜索单词或释义...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 200)
                    .onChange(of: searchText) { _, new in
                        dataService.search(new)
                    }
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        dataService.search("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Progress tag
            Button(action: { dataService.goToBookmark() }) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text(dataService.bookmarkIndex >= 0 ? "读到 #\(dataService.bookmarkIndex + 1) (\(Int(dataService.progressPercent))%)" : "未开始")
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }
}

// MARK: - Word List View (Sidebar)
struct WordListView: View {
    @Environment(DataService.self) private var dataService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("BEC")
                    .font(.custom("Georgia", size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("商务英语中级+高级")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(dataService.searchQuery.isEmpty
                     ? "\(dataService.totalCount) 词"
                     : "\(dataService.filteredCount) / \(dataService.totalCount) 词 (搜索结果)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 10)

            // Word list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(Array(dataService.filteredIndices.enumerated()), id: \.element) { _, idx in
                        let word = dataService.words[idx]
                        let isActive = idx == dataService.currentIndex
                        let isBookmarked = idx <= dataService.bookmarkIndex

                        Button(action: {
                            dataService.currentIndex = idx
                            dataService.saveBookmark()
                        }) {
                            HStack(spacing: 8) {
                                Text("#\(idx + 1)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 24, alignment: .trailing)

                                Text(word.en)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text(word.zh.components(separatedBy: CharacterSet(charactersIn: "；;")).first ?? "")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 70, alignment: .trailing)

                                if isBookmarked {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.orange.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isActive ? Color.primary.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Word Card View
struct WordCardView: View {
    @Environment(DataService.self) private var dataService
    @Environment(SpeechService.self) private var speechService

    var body: some View {
        ZStack {
            if let word = dataService.currentWord {
                VStack(spacing: 0) {
                    // Top info
                    HStack {
                        Text(dataService.searchQuery.isEmpty ? "BEC" : "BEC · 搜索")
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(.tertiary)
                        Spacer()
                        Text("#\(dataService.currentIndex + 1) / \(dataService.totalCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    Spacer()

                    // Card content
                    VStack(spacing: 0) {
                        Text(word.en)
                            .font(.custom("Georgia", size: min(CGFloat(56), CGFloat(600 - 50) / 5)))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                            .shadow(color: .white.opacity(0.3), radius: 20)

                        if !word.ipaDisplay.isEmpty {
                            Text(word.ipaDisplay)
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }

                        // Pronounce button
                        Button(action: { speechService.speak(word.en) }) {
                            Label("🔊 朗读发音 (空格键)", systemImage: "speaker.wave.2")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 14)

                        // Chinese definition
                        Text(word.zh)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(posColor(word.zh))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Example sentence
                        if !word.ex.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Divider()
                                    .padding(.top, 20)

                                Text("例句 · 点击朗读")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.tertiary)
                                    .textCase(.uppercase)

                                // English example (clickable)
                                Text(word.ex)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .lineSpacing(8)
                                    .onTapGesture { speechService.speak(word.ex) }
                                    .onHover { inside in
                                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                                    }

                                // Chinese translation of example
                                if !word.exZh.isEmpty {
                                    Text(word.exZh)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(6)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.top, 30)
                            .frame(maxWidth: 600)
                        }
                    }
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 40)
                    .background(.regularMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)

                    Spacer()

                    // Progress dots
                    ProgressDotsView()
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottomTrailing) {
                    Text("BEC VOCAB")
                        .font(.custom("Georgia", size: 10))
                        .foregroundColor(.tertiary.opacity(0.4))
                        .padding(.trailing, 24)
                        .padding(.bottom, 14)
                }
                // Auto-pronunciation on word change + initial load
                .onAppear {
                    // Initial pronunciation when view first appears
                    speechService.speak(word.en)
                }
                .onChange(of: dataService.currentIndex) { _, _ in
                    // Pronunciation on word switch
                    speechService.speak(word.en)
                    dataService.saveBookmark()
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Text("📖")
                        .font(.system(size: 48))
                    Text("BEC商务英语")
                        .font(.title2.weight(.medium))
                    Text("中级 + 高级 · 共 \(dataService.totalCount) 词")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
            }
        }
    }

    private func posColor(_ zh: String) -> Color {
        if zh.hasPrefix("n ") || zh.contains("n ") || zh.contains("n;") || zh.hasPrefix("n.") { return Color.blue.opacity(0.08) }
        if zh.hasPrefix("v ") || zh.contains("v ") || zh.hasPrefix("vt") || zh.hasPrefix("vi") || zh.hasPrefix("v.") { return Color.green.opacity(0.08) }
        if zh.hasPrefix("adj") || zh.contains("adj") { return Color.orange.opacity(0.08) }
        if zh.hasPrefix("adv") || zh.contains("adv") { return Color.purple.opacity(0.08) }
        return Color.clear
    }
}

// MARK: - Progress Dots
struct ProgressDotsView: View {
    @Environment(DataService.self) private var dataService

    var body: some View {
        let total = dataService.totalCount
        let maxDots = 200
        let step = max(1, total / maxDots)
        let dotCount = total / step + (total % step == 0 ? 0 : 1)

        HStack(spacing: 3) {
            ForEach(0..<dotCount, id: \.self) { i in
                Circle()
                    .fill(
                        i * step <= dataService.bookmarkIndex
                        ? Color.orange.opacity(0.5)
                        : i == dataService.currentIndex / step
                        ? Color.primary
                        : Color.primary.opacity(0.15)
                    )
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: 400)
    }
}

// MARK: - Color Extensions
extension Color {
    static let tertiary = Color.secondary.opacity(0.6)
}