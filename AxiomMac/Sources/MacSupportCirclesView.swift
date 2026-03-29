import SwiftUI

// MARK: - Support Circle Model

struct SupportCircle: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var focusBelief: String
    var memberIds: [UUID]
    var meetingDay: Int // 0-6 (Sunday-Saturday)
    var createdAt: Date

    init(id: UUID = UUID(), name: String, focusBelief: String, memberIds: [UUID] = [], meetingDay: Int, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.focusBelief = focusBelief
        self.memberIds = memberIds
        self.meetingDay = meetingDay
        self.createdAt = createdAt
    }

    var meetingDayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[meetingDay]
    }
}

struct WeeklyCheckIn: Identifiable, Codable {
    let id: UUID
    var circleId: UUID
    var memberId: UUID
    var weekOf: Date
    var rating: Int // 1-5
    var note: String?
    var completedAt: Date

    init(id: UUID = UUID(), circleId: UUID, memberId: UUID, weekOf: Date, rating: Int, note: String? = nil, completedAt: Date = Date()) {
        self.id = id
        self.circleId = circleId
        self.memberId = memberId
        self.weekOf = weekOf
        self.rating = rating
        self.note = note
        self.completedAt = completedAt
    }
}

// MARK: - MacSupportCirclesView

@MainActor
struct MacSupportCirclesView: View {
    @State private var selectedTab: CircleTab = .myCircles
    @State private var circles: [SupportCircle] = []
    @State private var checkIns: [WeeklyCheckIn] = []
    @State private var showingJoinBrowser = false
    @State private var showingNewCircle = false
    @State private var selectedCircle: SupportCircle?

    enum CircleTab: String, CaseIterable {
        case myCircles = "My Circles"
        case checkIn = "Weekly Check-In"
        case members = "Members"
        case browse = "Join Circle"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .background(Theme.background)
        .sheet(isPresented: $showingNewCircle) {
            NewCircleSheet { name, focusBelief, meetingDay in
                let circle = SupportCircle(name: name, focusBelief: focusBelief, meetingDay: meetingDay)
                circles.append(circle)
                saveCircles()
            }
        }
        .sheet(isPresented: $showingJoinBrowser) {
            JoinCircleBrowser()
        }
        .onAppear {
            loadCircles()
            loadCheckIns()
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(CircleTab.allCases, id: \.self) { tab in
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
                            .cornerRadius(Theme.cornerRadiusSmall)
                    }
                    .buttonStyle(.plain)
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
        case .myCircles:
            myCirclesView
        case .checkIn:
            checkInView
        case .members:
            membersView
        case .browse:
            JoinCircleBrowser()
        }
    }

    // MARK: - My Circles

    private var myCirclesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(circles.count) Circles")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showingNewCircle = true
                } label: {
                    Label("New Circle", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accentGold)
                }
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if circles.isEmpty {
                emptyCirclesView
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(circles) { circle in
                            CircleCard(circle: circle)
                                .onTapGesture { selectedCircle = circle }
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    private var emptyCirclesView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text("No Circles Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Join or create a support circle to work on beliefs with others")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }
            Button {
                showingJoinBrowser = true
            } label: {
                Text("Browse Circles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accentGold)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS)
                    .background(Theme.accentGold.opacity(0.15))
                    .cornerRadius(Theme.cornerRadiusPill)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Check-In

    private var checkInView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Weekly Check-In")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("Week of \(currentWeekString)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    ForEach(circles) { circle in
                        CheckInCard(circle: circle, checkIns: checkIns.filter { $0.circleId == circle.id }) { rating, note in
                            let checkIn = WeeklyCheckIn(circleId: circle.id, memberId: UUID(), weekOf: currentWeekStart, rating: rating, note: note)
                            checkIns.append(checkIn)
                            saveCheckIns()
                        }
                    }
                }
                .padding(Theme.screenMargin)
            }
        }
    }

    private var currentWeekStart: Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }

    private var currentWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = currentWeekStart
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    // MARK: - Members

    private var membersView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Circle Members")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if circles.isEmpty {
                VStack(spacing: Theme.spacingL) {
                    Spacer()
                    Text("Join a circle to see members")
                        .font(.callout)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(circles) { circle in
                            CircleMembersCard(circle: circle)
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    private func loadCircles() {
        if let data = UserDefaults.standard.data(forKey: "supportCircles"),
           let decoded = try? JSONDecoder().decode([SupportCircle].self, from: data) {
            circles = decoded
        }
    }

    private func saveCircles() {
        if let encoded = try? JSONEncoder().encode(circles) {
            UserDefaults.standard.set(encoded, forKey: "supportCircles")
        }
    }

    private func loadCheckIns() {
        if let data = UserDefaults.standard.data(forKey: "weeklyCheckIns"),
           let decoded = try? JSONDecoder().decode([WeeklyCheckIn].self, from: data) {
            checkIns = decoded
        }
    }

    private func saveCheckIns() {
        if let encoded = try? JSONEncoder().encode(checkIns) {
            UserDefaults.standard.set(encoded, forKey: "weeklyCheckIns")
        }
    }
}

// MARK: - Circle Card

struct CircleCard: View {
    let circle: SupportCircle

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(circle.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Focus: \(circle.focusBelief)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.spacingXS) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("\(circle.memberIds.count)")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.accentBlue)
                    Text(circle.meetingDayName)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            HStack {
                Label("View Circle", systemImage: "arrow.right.circle")
                    .font(.caption)
                    .foregroundColor(Theme.accentGold)
                Spacer()
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Check-In Card

struct CheckInCard: View {
    let circle: SupportCircle
    let checkIns: [WeeklyCheckIn]
    let onSubmit: (Int, String?) -> Void

    @State private var selectedRating: Int = 3
    @State private var note: String = ""
    @State private var hasCheckedIn: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text(circle.name)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("How did this week go with your belief work?")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: Theme.spacingS) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selectedRating = rating
                    } label: {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(rating <= selectedRating ? Theme.accentGold : Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Optional note...", text: $note)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacingS)
                .background(Theme.surfaceElevated)
                .cornerRadius(8)

            Button {
                onSubmit(selectedRating, note.isEmpty ? nil : note)
                hasCheckedIn = true
            } label: {
                Text(hasCheckedIn ? "✓ Checked In" : "Submit Check-In")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(hasCheckedIn ? Theme.accentGreen : Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingS)
                    .background(hasCheckedIn ? Theme.accentGreen.opacity(0.15) : Theme.accentGold.opacity(0.15))
                    .cornerRadius(8)
            }
            .disabled(hasCheckedIn)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Circle Members Card

struct CircleMembersCard: View {
    let circle: SupportCircle

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text(circle.name)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(circle.memberIds.count) members")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Text("Working on: \"\(circle.focusBelief)\"")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .italic()

            Divider()

            HStack(spacing: -8) {
                ForEach(0..<min(circle.memberIds.count, 6), id: \.self) { index in
                    Circle()
                        .fill(Theme.accentBlue.opacity(0.3 + Double(index) * 0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(index + 1))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.surface, lineWidth: 2)
                        )
                }
                if circle.memberIds.count > 6 {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("+\(circle.memberIds.count - 6)")
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.surface, lineWidth: 2)
                        )
                }
                Spacer()
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - New Circle Sheet

struct NewCircleSheet: View {
    let onSave: (String, String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var focusBelief = ""
    @State private var meetingDay = 1

    private let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    TextField("Circle Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusMedium)

                    TextField("What belief are you working on together?", text: $focusBelief, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .lineLimit(2...4)

                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Meeting Day")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Picker("Meeting Day", selection: $meetingDay) {
                            ForEach(0..<7, id: \.self) { index in
                                Text(days[index]).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("New Support Circle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(name, focusBelief, meetingDay)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || focusBelief.isEmpty)
                }
            }
        }
    }
}

// MARK: - Join Circle Browser

struct JoinCircleBrowser: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var availableCircles: [SupportCircle] = [
        SupportCircle(name: "Imposter Syndrome Warriors", focusBelief: "I don't belong here", meetingDay: 1),
        SupportCircle(name: "Perfectionism Release", focusBelief: "I must be perfect to be valued", meetingDay: 2),
        SupportCircle(name: "Self-Compassion Circle", focusBelief: "I am worthy of kindness", meetingDay: 3),
        SupportCircle(name: "Anxiety Support Group", focusBelief: "I cannot handle uncertainty", meetingDay: 4),
        SupportCircle(name: "Relationship Trust", focusBelief: "People will leave me", meetingDay: 0),
    ]

    var filteredCircles: [SupportCircle] {
        if searchText.isEmpty {
            return availableCircles
        }
        return availableCircles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.focusBelief.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    TextField("Search circles...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .padding(Theme.screenMargin)

                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            ForEach(filteredCircles) { circle in
                                JoinableCircleCard(circle: circle)
                            }
                        }
                        .padding(.horizontal, Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("Join a Circle")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

struct JoinableCircleCard: View {
    let circle: SupportCircle
    @State private var isJoined = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(circle.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("\"\(circle.focusBelief)\"")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.spacingXS) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("\(circle.memberIds.count)")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.accentBlue)
                    Text(circle.meetingDayName)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            HStack {
                Text("5-8 members recommended")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button {
                    isJoined.toggle()
                } label: {
                    Text(isJoined ? "✓ Joined" : "Join Circle")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isJoined ? Theme.accentGreen : Theme.accentGold)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingXS)
                        .background(isJoined ? Theme.accentGreen.opacity(0.15) : Theme.accentGold.opacity(0.15))
                        .cornerRadius(Theme.cornerRadiusPill)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}
