import SwiftUI

// MARK: - Shared Models for Group Belief Work

struct SharedBeliefProject: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var memberIds: [UUID]
    var beliefText: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, description: String, memberIds: [UUID] = [], beliefText: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.memberIds = memberIds
        self.beliefText = beliefText
        self.createdAt = createdAt
    }
}

struct GroupSession: Identifiable, Codable {
    let id: UUID
    var projectId: UUID
    var title: String
    var participantIds: [UUID]
    var startedAt: Date
    var endedAt: Date?
    var notes: String

    init(id: UUID = UUID(), projectId: UUID, title: String, participantIds: [UUID] = [], startedAt: Date = Date(), endedAt: Date? = nil, notes: String = "") {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.participantIds = participantIds
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }

    var isActive: Bool { endedAt == nil }
    var duration: TimeInterval { (endedAt ?? Date()).timeIntervalSince(startedAt) }
}

struct BeliefNode: Identifiable {
    let id: UUID
    let belief: Belief
    var position: CGPoint
}

// MARK: - MacGroupBeliefView

@MainActor
struct MacGroupBeliefView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedTab: GroupTab = .projects
    @State private var showingNewProject = false
    @State private var projects: [SharedBeliefProject] = []
    @State private var sessions: [GroupSession] = []
    @State private var selectedProject: SharedBeliefProject?
    @State private var showingWorkshopBuilder = false

    enum GroupTab: String, CaseIterable {
        case projects = "Projects"
        case mapping = "Belief Map"
        case sessions = "Sessions"
        case builder = "Workshop Builder"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .background(Theme.background)
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet { title, description, beliefText in
                let project = SharedBeliefProject(title: title, description: description, beliefText: beliefText)
                projects.append(project)
            }
        }
        .sheet(isPresented: $showingWorkshopBuilder) {
            WorkshopBuilderSheet(onSave: { (_: Workshop) in })
        }
        .onAppear {
            loadData()
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(GroupTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(selectedTab == tab ? Theme.accentGold.opacity(0.15) : Color.clear)
                            .cornerRadius(Theme.cornerRadiusS)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.rawValue)
                    .accessibilityAddTraits(selectedTab == tab ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, Theme.spacingS)
        }
        .background(Theme.surface)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .projects:
            projectsView
        case .mapping:
            beliefMapView
        case .sessions:
            sessionsView
        case .builder:
            workshopBuilderView
        }
    }

    // MARK: - Projects Tab

    private var projectsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(projects.count) Shared Projects")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showingNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accentGold)
                }
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if projects.isEmpty {
                emptyStateView(
                    icon: "person.3.fill",
                    title: "No Shared Projects Yet",
                    subtitle: "Create a shared belief project to work on with others"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(projects) { project in
                            ProjectCard(project: project, memberCount: project.memberIds.count)
                                .onTapGesture { selectedProject = project }
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Belief Map Tab

    private var beliefMapView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Group Belief Network")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(databaseService.allBeliefs.count) beliefs")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            BeliefNetworkGraph(beliefs: databaseService.allBeliefs, connections: databaseService.allConnections)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Sessions Tab

    private var sessionsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Group Sessions")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(sessions.filter { $0.isActive }.count) active")
                    .font(.caption)
                    .foregroundColor(Theme.accentGreen)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if sessions.isEmpty {
                emptyStateView(
                    icon: "video.fill",
                    title: "No Sessions Yet",
                    subtitle: "Start a group session when working on a shared project"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(sessions) { session in
                            SessionCard(session: session)
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    // MARK: - Workshop Builder Tab

    private var workshopBuilderView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Workshop Builder")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showingWorkshopBuilder = true
                } label: {
                    Label("New Workshop", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accentGold)
                }
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            WorkshopBuilderList()
                .frame(maxHeight: .infinity)
        }
    }

    private func loadData() {
        // Load from UserDefaults for now (in production would use DatabaseService extensions)
        if let data = UserDefaults.standard.data(forKey: "sharedProjects"),
           let decoded = try? JSONDecoder().decode([SharedBeliefProject].self, from: data) {
            projects = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "groupSessions"),
           let decoded = try? JSONDecoder().decode([GroupSession].self, from: data) {
            sessions = decoded
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: SharedBeliefProject
    let memberCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(project.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.spacingXS) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(memberCount)")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.accentBlue)
                }
            }

            Text("\"\(project.beliefText)\"")
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .italic()
                .lineLimit(2)
                .padding(Theme.spacingS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentGold.opacity(0.08))
                .cornerRadius(8)

            HStack {
                Label("Start Session", systemImage: "play.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accentGreen)
                Spacer()
                Label("View Details", systemImage: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: GroupSession

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Circle()
                .fill(session.isActive ? Theme.accentGreen : Theme.textSecondary)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: Theme.spacingS) {
                    Text("\(session.participantIds.count) participants")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            if session.isActive {
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.accentGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGreen.opacity(0.15))
                    .cornerRadius(4)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Belief Network Graph

struct BeliefNetworkGraph: View {
    let beliefs: [Belief]
    let connections: [BeliefConnection]

    @State private var nodes: [BeliefNode] = []
    @State private var draggedNode: BeliefNode?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw connections first (behind nodes)
                ForEach(connections) { connection in
                    if let from = nodes.first(where: { $0.id == connection.fromBeliefId }),
                       let to = nodes.first(where: { $0.id == connection.toBeliefId }) {
                        Path { path in
                            path.move(to: from.position)
                            path.addLine(to: to.position)
                        }
                        .stroke(Theme.accentGold.opacity(connection.strength * 0.5 + 0.2), lineWidth: CGFloat(connection.strength * 2))
                    }
                }

                // Draw nodes
                ForEach(nodes) { node in
                    NodeView(belief: node.belief, isSelected: draggedNode?.id == node.id)
                        .position(node.position)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if let index = nodes.firstIndex(where: { $0.id == node.id }) {
                                        nodes[index].position = value.location
                                    }
                                }
                        )
                }
            }
            .onAppear {
                initializeNodes(in: geometry.size)
            }
        }
        .background(Theme.background)
    }

    private func initializeNodes(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = min(size.width, size.height) / 3

        nodes = beliefs.enumerated().map { index, belief in
            let angle = (2 * .pi * Double(index)) / Double(max(beliefs.count, 1))
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            return BeliefNode(id: belief.id, belief: belief, position: CGPoint(x: x, y: y))
        }
    }
}

struct NodeView: View {
    let belief: Belief
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Theme.scoreColor(for: belief.score))
                .frame(width: 12, height: 12)

            Text(belief.text)
                .font(.caption2)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .frame(width: 80)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingS)
        .background(Theme.surface.opacity(0.9))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Theme.accentGold : Theme.border, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var beliefText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    TextField("Project Title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)

                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)
                        .lineLimit(2...4)

                    TextField("Target Belief (what are you working on together?)", text: $beliefText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)
                        .lineLimit(2...4)

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("New Shared Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(title, description, beliefText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || beliefText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Workshop Builder

struct WorkshopBuilderList: View {
    @State private var workshops: [Workshop] = Workshop.builtInWorkshops

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(workshops) { workshop in
                    WorkshopBuilderCard(workshop: workshop)
                }
            }
            .padding(Theme.screenMargin)
        }
    }
}

struct WorkshopBuilderCard: View {
    let workshop: Workshop

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    if workshop.isBuiltIn {
                        Text("BUILT-IN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.accentBlue)
                    }
                    Text(workshop.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(workshop.description)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(workshop.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingS) {
                    ForEach(workshop.exercises.prefix(5)) { exercise in
                        ExerciseTypeChip(type: exercise.type)
                    }
                    if workshop.exercises.count > 5 {
                        Text("+\(workshop.exercises.count - 5)")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

struct ExerciseTypeChip: View {
    let type: ExerciseType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(type.rawValue.capitalized)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }

    private var icon: String {
        switch type {
        case .reflection: return "brain.head.profile"
        case .guided: return "figure.walk"
        case .group: return "person.3.fill"
        case .quiz: return "questionmark.circle"
        }
    }

    private var color: Color {
        switch type {
        case .reflection: return Theme.accentBlue
        case .guided: return Theme.accentGreen
        case .group: return Theme.accentGold
        case .quiz: return Theme.accentRed
        }
    }
}

struct WorkshopBuilderSheet: View {
    let onSave: (Workshop) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    TextField("Workshop Title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)

                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)
                        .lineLimit(2...4)

                    Text("Add exercises after creation")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("New Workshop")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let workshop = Workshop(id: UUID(), title: title, description: description, exercises: [], isBuiltIn: false)
                        onSave(workshop)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
