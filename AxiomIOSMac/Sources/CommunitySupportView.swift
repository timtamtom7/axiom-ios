import SwiftUI

// MARK: - Community Models

struct CommunityMember: Identifiable, Codable {
    let id: UUID
    var displayName: String
    var joinedAt: Date
    var trustScore: Int
    var badge: MemberBadge
    var isAnonymous: Bool
    var postsCount: Int
    var helpedCount: Int
}

enum MemberBadge: String, Codable {
    case newcomer = "Newcomer"
    case supporter = "Supporter"
    case wise = "Wise"
    case anchor = "Anchor"

    var icon: String {
        switch self {
        case .newcomer: return "leaf"
        case .supporter: return "heart"
        case .wise: return "lightbulb"
        case .anchor: return "anchor"
        }
    }

    var color: Color {
        switch self {
        case .newcomer: return .green
        case .supporter: return .pink
        case .wise: return .orange
        case .anchor: return .purple
        }
    }
}

struct SupportCircle: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var memberCount: Int
    var isJoined: Bool
    var topics: [String]
    var meetingTime: String?
}

struct CommunityThread: Identifiable, Codable {
    let id: UUID
    var title: String
    var body: String
    var authorId: UUID
    var authorName: String
    var createdAt: Date
    var replyCount: Int
    var upvotes: Int
    var isPinned: Bool
    var tags: [String]
    var hasTherapistReply: Bool
}

struct WisdomEntry: Identifiable, Codable {
    let id: UUID
    var quote: String
    var authorId: UUID?
    var authorName: String
    var submittedAt: Date
    var upvotes: Int
    var isApproved: Bool
    var category: String
}

struct AccountabilityPartner: Identifiable, Codable {
    let id: UUID
    var partnerId: UUID
    var partnerName: String
    var pairedAt: Date
    var checkInStreak: Int
    var lastCheckIn: Date?
    var goals: [String]
}

// MARK: - Community Support View

struct CommunitySupportView: View {
    @State private var activeTab: CommunityTab = .circles
    @State private var circles: [SupportCircle] = SupportCircle.mockCircles
    @State private var threads: [CommunityThread] = CommunityThread.mockThreads
    @State private var wisdomEntries: [WisdomEntry] = WisdomEntry.mockEntries
    @State private var selectedThread: CommunityThread?
    @State private var showingNewPost = false
    @State private var searchText = ""

    enum CommunityTab: String, CaseIterable {
        case circles = "Circles"
        case discussions = "Discussions"
        case wisdom = "Wisdom"
        case partners = "Partners"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabSelector
                searchBar

                switch activeTab {
                case .circles:
                    circlesList
                case .discussions:
                    discussionsList
                case .wisdom:
                    wisdomList
                case .partners:
                    partnersView
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewPost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView { title, body, tags in
                    createThread(title: title, body: body, tags: tags)
                }
            }
            .sheet(item: $selectedThread) { thread in
                ThreadDetailView(thread: thread, onReply: { reply in
                    addReply(to: thread, reply: reply)
                })
            }
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CommunityTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(_ tab: CommunityTab) -> some View {
        Button {
            activeTab = tab
        } label: {
            Text(tab.rawValue)
                .font(.subheadline)
                .fontWeight(activeTab == tab ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    activeTab == tab
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                )
                .foregroundColor(activeTab == tab ? .accentColor : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search community...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Circles Tab

    private var circlesList: some View {
        List {
            ForEach(circles) { circle in
                CircleRowView(circle: circle) {
                    toggleCircle(circle)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Discussions Tab

    private var discussionsList: some View {
        List {
            ForEach(filteredThreads) { thread in
                ThreadRowView(thread: thread)
                    .onTapGesture {
                        selectedThread = thread
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    private var filteredThreads: [CommunityThread] {
        if searchText.isEmpty {
            return threads
        }
        return threads.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Wisdom Tab

    private var wisdomList: some View {
        List {
            ForEach(wisdomEntries.filter { $0.isApproved }) { entry in
                WisdomRowView(entry: entry)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Partners Tab

    private var partnersView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Find an Accountability Partner")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect with someone who understands.\nShare goals, check in daily, grow together.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Find a Partner") {
                // Would open partner matching flow
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func toggleCircle(_ circle: SupportCircle) {
        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index].isJoined.toggle()
            circles[index].memberCount += circles[index].isJoined ? 1 : -1
        }
    }

    private func createThread(title: String, body: String, tags: [String]) {
        let thread = CommunityThread(
            id: UUID(),
            title: title,
            body: body,
            authorId: UUID(),
            authorName: "You",
            createdAt: Date(),
            replyCount: 0,
            upvotes: 0,
            isPinned: false,
            tags: tags,
            hasTherapistReply: false
        )
        threads.insert(thread, at: 0)
    }

    private func addReply(to thread: CommunityThread, reply: String) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].replyCount += 1
        }
    }
}

// MARK: - Circle Row View

struct CircleRowView: View {
    let circle: SupportCircle
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(circle.name)
                    .font(.headline)

                Spacer()

                Button(circle.isJoined ? "Leave" : "Join") {
                    onJoin()
                }
                .buttonStyle(.bordered)
                .tint(circle.isJoined ? .red : .accentColor)
            }

            Text(circle.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(circle.memberCount) members", systemImage: "person.2")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(circle.topics.prefix(3), id: \.self) { topic in
                    Text(topic)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thread Row View

struct ThreadRowView: View {
    let thread: CommunityThread

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Text(thread.title)
                    .font(.headline)
                    .lineLimit(1)

                if thread.hasTherapistReply {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Text(thread.body)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text("u/\(thread.authorName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text(thread.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    Label("\(thread.upvotes)", systemImage: "arrow.up")
                    Label("\(thread.replyCount)", systemImage: "bubble.right")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            if !thread.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(thread.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Wisdom Row View

struct WisdomRowView: View {
    let entry: WisdomEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(entry.quote)\"")
                .font(.body)
                .italic()

            HStack {
                Text("— \(entry.authorName)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("\(entry.upvotes)", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(entry.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.categoryColor.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

extension WisdomEntry {
    var categoryColor: Color {
        switch category.lowercased() {
        case "anxiety": return .blue
        case "hope": return .green
        case "courage": return .orange
        case "wisdom": return .purple
        default: return .gray
        }
    }
}

// MARK: - New Post View

struct NewPostView: View {
    let onPost: (String, String, [String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What's on your mind?", text: $title)
                }

                Section("Details") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 120)
                }

                Section("Tags") {
                    HStack {
                        TextField("Add a tag...", text: $tagInput)
                        Button("Add") {
                            if !tagInput.isEmpty {
                                tags.append(tagInput)
                                tagInput = ""
                            }
                        }
                    }

                    FlowLayout(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }

                Section {
                    Text("Share anonymously — your identity stays private")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Post")
            #if os(iOS)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        onPost(title, bodyText, tags)
                        dismiss()
                    }
                    .disabled(title.isEmpty || bodyText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Thread Detail View

struct ThreadDetailView: View {
    let thread: CommunityThread
    let onReply: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var replyText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(thread.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text("Posted by u/\(thread.authorName)")
                        Text("•")
                        Text(thread.createdAt, style: .date)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text(thread.body)
                        .font(.body)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(thread.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }

                    Divider()

                    Text("Replies (\(thread.replyCount))")
                        .font(.headline)

                    // Placeholder for actual replies
                    Text("No replies yet. Be the first to share your thoughts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()

                    Spacer()
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Write a reply...", text: $replyText)
                        .textFieldStyle(.roundedBorder)

                    Button("Reply") {
                        onReply(replyText)
                        replyText = ""
                    }
                    .disabled(replyText.isEmpty)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .navigationTitle("Discussion")
            #if os(iOS)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Mock Data

extension SupportCircle {
    static let mockCircles: [SupportCircle] = [
        SupportCircle(
            id: UUID(),
            name: "Daily Anxiety Support",
            description: "People who also struggle with anxiety. Share experiences, offer support.",
            memberCount: 124,
            isJoined: true,
            topics: ["anxiety", "daily-check-in", "mutual-support"],
            meetingTime: "Daily 9pm EST"
        ),
        SupportCircle(
            id: UUID(),
            name: "CBT Practice Group",
            description: "Working through CBT exercises together. Share progress and insights.",
            memberCount: 89,
            isJoined: false,
            topics: ["CBT", "exercises", "belief-work"],
            meetingTime: "Wednesdays 7pm EST"
        ),
        SupportCircle(
            id: UUID(),
            name: "Mindfulness & Meditation",
            description: "Gentle practices for grounding and presence.",
            memberCount: 203,
            isJoined: false,
            topics: ["mindfulness", "meditation", "breathing"],
            meetingTime: nil
        ),
        SupportCircle(
            id: UUID(),
            name: "Progress Celebration",
            description: "Big and small wins. We celebrate every step forward.",
            memberCount: 156,
            isJoined: true,
            topics: ["wins", "celebration", "positivity"],
            meetingTime: nil
        )
    ]
}

extension CommunityThread {
    static let mockThreads: [CommunityThread] = [
        CommunityThread(
            id: UUID(),
            title: "What helps you when anxiety peaks?",
            body: "I've been having a rough week and want to hear what's working for others. Morning anxiety has been especially tough.",
            authorId: UUID(),
            authorName: "anxious_squirrel",
            createdAt: Date().addingTimeInterval(-3600),
            replyCount: 23,
            upvotes: 47,
            isPinned: true,
            tags: ["anxiety", "coping", "support"],
            hasTherapistReply: true
        ),
        CommunityThread(
            id: UUID(),
            title: "Completed my first decatastrophizing exercise!",
            body: "Took me 3 tries to get through it but I actually felt better after. The 'what's most likely to happen' question really helped.",
            authorId: UUID(),
            authorName: "hopeful_change",
            createdAt: Date().addingTimeInterval(-7200),
            replyCount: 12,
            upvotes: 89,
            isPinned: false,
            tags: ["CBT", "win", "decatastrophizing"],
            hasTherapistReply: false
        ),
        CommunityThread(
            id: UUID(),
            title: "Question about evidence weighing",
            body: "How do you handle evidence that's mixed? Like some evidence supports the belief but some contradicts it?",
            authorId: UUID(),
            authorName: "curious_mind",
            createdAt: Date().addingTimeInterval(-14400),
            replyCount: 8,
            upvotes: 34,
            isPinned: false,
            tags: ["CBT", "evidence", "question"],
            hasTherapistReply: true
        )
    ]
}

extension WisdomEntry {
    static let mockEntries: [WisdomEntry] = [
        WisdomEntry(
            id: UUID(),
            quote: "The thought is not the fact. You can have thoughts without them being true.",
            authorId: nil,
            authorName: "Community Member",
            submittedAt: Date().addingTimeInterval(-86400),
            upvotes: 234,
            isApproved: true,
            category: "wisdom"
        ),
        WisdomEntry(
            id: UUID(),
            quote: "Progress isn't linear. Some days standing still is the bravest thing you do.",
            authorId: nil,
            authorName: "Anonymous",
            submittedAt: Date().addingTimeInterval(-172800),
            upvotes: 189,
            isApproved: true,
            category: "courage"
        ),
        WisdomEntry(
            id: UUID(),
            quote: "When I'm in the storm, I remind myself: this too shall pass. It always has before.",
            authorId: nil,
            authorName: "Community Member",
            submittedAt: Date().addingTimeInterval(-259200),
            upvotes: 156,
            isApproved: true,
            category: "hope"
        ),
        WisdomEntry(
            id: UUID(),
            quote: "I used to think feeling anxious meant something was wrong. Now I see it as my mind trying to protect me.",
            authorId: nil,
            authorName: "longtimer",
            submittedAt: Date().addingTimeInterval(-345600),
            upvotes: 201,
            isApproved: true,
            category: "anxiety"
        )
    ]
}
