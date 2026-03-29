import SwiftUI

/// R7: Support Circles view — community groups for mutual support
struct SupportCirclesView: View {
    @StateObject private var circlesStore = SupportCirclesStore.shared
    @State private var selectedCircle: SupportCircleData?
    @State private var showingCreateCircle = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    if filteredCircles.isEmpty {
                        emptyState
                    } else {
                        circlesList
                    }
                }
            }
            .navigationTitle("Support Circles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateCircle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCircle) {
                CreateCircleSheet()
            }
            .sheet(item: $selectedCircle) { circle in
                CircleDetailSheet(circle: circle)
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)
            TextField("Search circles...", text: $searchText)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .padding(Theme.screenMargin)
    }

    private var circlesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(filteredCircles) { circle in
                    CircleCard(circle: circle)
                        .onTapGesture {
                            selectedCircle = circle
                        }
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "person.3",
                title: "No Circles Yet",
                subtitle: "Create or join a support circle to connect with others.",
                actionTitle: "Create a Circle"
            ) {
                showingCreateCircle = true
            }
            Spacer()
        }
    }

    private var filteredCircles: [SupportCircleData] {
        if searchText.isEmpty {
            return circlesStore.circles
        }
        return circlesStore.circles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.topics.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - Circle Card

struct CircleCard: View {
    let circle: SupportCircleData
    @State private var isJoining = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: Theme.spacingS) {
                        Label("\(circle.memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)

                        if circle.isPrivate {
                            Label("Private", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }

                Spacer()

                // Join button
                Button {
                    joinCircle()
                } label: {
                    if isJoining {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text(circle.isJoined ? "Leave" : "Join")
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(circle.isJoined ? Theme.surfaceElevated : Theme.accentBlue)
                .foregroundColor(circle.isJoined ? Theme.textPrimary : .white)
                .cornerRadius(Theme.cornerRadiusPill)
            }

            // Description
            Text(circle.description)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)

            // Topics
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingS) {
                    ForEach(circle.topics, id: \.self) { topic in
                        Text("#\(topic)")
                            .font(.caption)
                            .foregroundColor(Theme.accentBlue)
                            .padding(.horizontal, Theme.spacingS)
                            .padding(.vertical, 4)
                            .background(Theme.accentBlue.opacity(0.1))
                            .cornerRadius(Theme.cornerRadiusS)
                    }
                }
            }

            // Meeting time
            if let meetingTime = circle.meetingTime {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    Text(meetingTime)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            // Recent activity
            HStack {
                Text("Active \(circle.lastActivity.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Circle()
                    .fill(circle.isActive ? Theme.accentGreen : Theme.textSecondary)
                    .frame(width: 8, height: 8)
                Text(circle.isActive ? "Active now" : "Inactive")
                    .font(.caption2)
                    .foregroundColor(circle.isActive ? Theme.accentGreen : Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circle.name). \(circle.memberCount) members. \(circle.description). \(circle.isJoined ? "You are a member" : "Join to participate")")
    }

    private func joinCircle() {
        isJoining = true
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            SupportCirclesStore.shared.toggleMembership(circle)
            isJoining = false
        }
    }
}

// MARK: - Circle Detail Sheet

struct CircleDetailSheet: View {
    let circle: SupportCircleData
    @Environment(\.dismiss) private var dismiss
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text(circle.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)

                            HStack {
                                Label("\(circle.memberCount) members", systemImage: "person.2")
                                Spacer()
                                if circle.isActive {
                                    Label("Active", systemImage: "circle.fill")
                                        .foregroundColor(Theme.accentGreen)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        }

                        // Description
                        Text(circle.description)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)

                        // Topics
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Topics")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            FlowLayout(spacing: Theme.spacingS) {
                                ForEach(circle.topics, id: \.self) { topic in
                                    Text("#\(topic)")
                                        .font(.caption)
                                        .foregroundColor(Theme.accentBlue)
                                        .padding(.horizontal, Theme.spacingS)
                                        .padding(.vertical, 4)
                                        .background(Theme.accentBlue.opacity(0.1))
                                        .cornerRadius(Theme.cornerRadiusS)
                                }
                            }
                        }

                        // Meeting schedule
                        if let meetingTime = circle.meetingTime {
                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                Text("Meeting Schedule")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                Label(meetingTime, systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        // Guidelines
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Community Guidelines")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            ForEach(circle.guidelines, id: \.self) { guideline in
                                HStack(alignment: .top, spacing: Theme.spacingS) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accentGreen)
                                        .font(.caption)
                                    Text(guideline)
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(Theme.screenMargin)
                }

                // Bottom CTA
                VStack {
                    Spacer()
                    Button {
                        joinCircle()
                    } label: {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(circle.isJoined ? "Leave Circle" : "Join Circle")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(circle.isJoined ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(circle.isJoined ? Theme.textPrimary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func joinCircle() {
        isJoining = true
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            SupportCirclesStore.shared.toggleMembership(circle)
            isJoining = false
        }
    }
}

// MARK: - Create Circle Sheet

struct CreateCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var topics: [String] = []
    @State private var topicInput = ""
    @State private var meetingTime = ""
    @State private var isPrivate = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        // Name
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Circle Name")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("e.g. Daily Anxiety Support", text: $name)
                                .textFieldStyle(.plain)
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextEditor(text: $description)
                                .frame(minHeight: 80)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                                .foregroundColor(Theme.textPrimary)
                        }

                        // Topics
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Topics")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            HStack {
                                TextField("Add a topic", text: $topicInput)
                                    .textFieldStyle(.plain)
                                Button("Add") {
                                    if !topicInput.isEmpty {
                                        topics.append(topicInput)
                                        topicInput = ""
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(Theme.accentBlue)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)

                            FlowLayout(spacing: Theme.spacingS) {
                                ForEach(topics, id: \.self) { topic in
                                    HStack(spacing: 4) {
                                        Text(topic)
                                        Button {
                                            topics.removeAll { $0 == topic }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, Theme.spacingS)
                                    .padding(.vertical, 4)
                                    .background(Theme.accentBlue.opacity(0.1))
                                    .cornerRadius(Theme.cornerRadiusS)
                                }
                            }
                        }

                        // Meeting time
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Meeting Schedule (optional)")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("e.g. Daily 9pm EST", text: $meetingTime)
                                .textFieldStyle(.plain)
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                        }

                        // Private toggle
                        Toggle(isOn: $isPrivate) {
                            VStack(alignment: .leading) {
                                Text("Private Circle")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                                Text("Only invited members can join")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .tint(Theme.accentBlue)
                    }
                    .padding(Theme.screenMargin)
                }

                // Bottom CTA
                VStack {
                    Spacer()
                    Button {
                        createCircle()
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Create Circle")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(name.isEmpty ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(name.isEmpty ? Theme.textSecondary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .disabled(name.isEmpty || isCreating)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createCircle() {
        isCreating = true
        let newCircle = SupportCircleData(
            id: UUID(),
            name: name,
            description: description,
            memberCount: 1,
            isJoined: true,
            topics: topics,
            meetingTime: meetingTime.isEmpty ? nil : meetingTime,
            isPrivate: isPrivate,
            isActive: true,
            lastActivity: Date(),
            guidelines: [
                "Be respectful and supportive",
                "Share from personal experience only",
                "No medical or professional advice",
                "What happens in the circle, stays in the circle"
            ]
        )
        SupportCirclesStore.shared.addCircle(newCircle)
        dismiss()
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

#Preview {
    SupportCirclesView()
        .preferredColorScheme(.dark)
}
