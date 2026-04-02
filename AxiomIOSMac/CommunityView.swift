import SwiftUI

struct CommunityView: View {
    @State private var selectedSegment = 0
    @State private var posts: [CommunityPost] = CommunityPost.samplePosts()
    @State private var showingNewPost = false

    var body: some View {
        VStack(spacing: 0) {
            // Segment control
            Picker("View", selection: $selectedSegment) {
                Text("Feed").tag(0)
                Text("Debates").tag(1)
                Text("Evidence Library").tag(2)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Community view selection")
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 14) {
                    if selectedSegment == 0 {
                        ForEach(posts) { post in
                            CommunityPostCard(post: post, onJoinDebate: { selectedSegment = 1 })
                        }
                    } else if selectedSegment == 1 {
                        ForEach(posts.filter { $0.upvotes > 3 }) { post in
                            DebateCard(post: post)
                        }
                    } else {
                        EvidenceLibraryView()
                    }
                }
                .padding(20)
            }
        }
        .background(Theme.surface)
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingNewPost = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.gold)
                    .clipShape(Circle())
                    .shadow(color: Theme.gold.opacity(0.4), radius: 4, y: 2)
            }
            .accessibilityLabel("Create new community post")
            .accessibilityHint("Opens a sheet to share a belief with the community")
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .padding(20)
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostSheet(isPresented: $showingNewPost, posts: $posts)
        }
    }
}

struct CommunityPostCard: View {
    let post: CommunityPost
    var onJoinDebate: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if post.isAnonymous {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 10))
                        Text("Anonymous")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 10))
                        Text("Community Member")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
                Text(post.timestamp.formatted(.relative(presentation: .named)))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Text("\"\(post.beliefText)\"")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(Theme.navy)
                .italic()
                .lineLimit(2)

            Text(post.postText)
                .font(.system(size: 12))
                .foregroundColor(Theme.navy.opacity(0.8))
                .lineLimit(3)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up").font(.system(size: 11))
                    Text("\(post.upvotes)")
                        .font(.system(size: 11))
                }
                .foregroundColor(Theme.gold)
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left").font(.system(size: 11))
                    Text("\(post.comments)")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                Spacer()
                Button {
                    onJoinDebate?()
                } label: {
                    Text("Join Debate")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.gold)
                }
                .accessibilityLabel("Join debate on this belief")
            }
        }
        .padding(14)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct DebateCard: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ongoing Debate")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.gold)
                    Text(post.beliefText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.navy)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill").font(.system(size: 10))
                    Text("\(post.upvotes + 2)")
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary)
            }

            Text(post.postText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle").font(.system(size: 11))
                        .foregroundColor(Theme.accentGreen)
                    Text("For: \(post.upvotes)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accentGreen)
                }
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle").font(.system(size: 11))
                        .foregroundColor(Theme.accentRed)
                    Text("Against: \(post.comments)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accentRed)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.gold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct EvidenceLibraryView: View {
    let items: [EvidenceLibraryItem] = EvidenceLibraryItem.sample()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evidence Library")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.navy)
            Text("Common beliefs and the evidence around them")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.gold.opacity(0.5))
                    Text("No evidence library items yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Evidence library items will appear here when shared by the community")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(items) { item in
                    EvidenceLibraryCard(item: item)
                }
            }
        }
    }
}

struct EvidenceLibraryCard: View {
    let item: EvidenceLibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.belief)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.navy)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("For")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.accentGreen)
                    Text(item.forEvidence)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Theme.surface)
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Against")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.accentRed)
                    Text(item.againstEvidence)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Theme.cardBg)
        .cornerRadius(12)
    }
}

struct EvidenceLibraryItem: Identifiable {
    let id = UUID()
    let belief: String
    let forEvidence: String
    let againstEvidence: String
}

struct NewPostSheet: View {
    @Binding var isPresented: Bool
    @Binding var posts: [CommunityPost]
    @State private var beliefText = ""
    @State private var postText = ""
    @State private var isAnonymous = true

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Share to Community")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .foregroundColor(Theme.gold)
            }

            TextField("The belief you're exploring...", text: $beliefText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(8)

            TextEditor(text: $postText)
                .font(.system(size: 13))
                .frame(height: 80)
                .padding(8)
                .background(Theme.surface)
                .cornerRadius(8)

            Toggle(isOn: $isAnonymous) {
                Text("Post anonymously")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.switch)
            .tint(Theme.gold)

            Button {
                let post = CommunityPost(
                    id: UUID(),
                    beliefText: beliefText,
                    postText: postText,
                    timestamp: Date(),
                    isAnonymous: isAnonymous,
                    upvotes: 0,
                    comments: 0
                )
                posts.insert(post, at: 0)
                isPresented = false
            } label: {
                Text("Share")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.navy)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Theme.cream)
        .frame(width: 360)
    }
}

extension CommunityPost {
    static func samplePosts() -> [CommunityPost] {
        [
            CommunityPost(id: UUID(), beliefText: "I should always put others first", postText: "I've been working on this belief and realized it actually causes me to resent people when I don't get what I need back.", timestamp: Date().addingTimeInterval(-3600), isAnonymous: true, upvotes: 5, comments: 3),
            CommunityPost(id: UUID(), beliefText: "I'm not good enough", postText: "Evidence from my childhood keeps supporting this, but I'm starting to see the pattern. Looking for perspectives.", timestamp: Date().addingTimeInterval(-7200), isAnonymous: false, upvotes: 12, comments: 8),
            CommunityPost(id: UUID(), beliefText: "Failure defines me", postText: "I failed that exam but I've been reframing it — failure is data, not identity. Anyone else try this?", timestamp: Date().addingTimeInterval(-86400), isAnonymous: true, upvotes: 7, comments: 5)
        ]
    }
}

extension EvidenceLibraryItem {
    static func sample() -> [EvidenceLibraryItem] {
        [
            EvidenceLibraryItem(belief: "I am not good enough", forEvidence: "Many studies show early criticism shapes core beliefs", againstEvidence: "Self-worth is not fixed; it can grow with evidence"),
            EvidenceLibraryItem(belief: "I should always be productive", forEvidence: "Society rewards consistent output and achievement", againstEvidence: "Rest is essential for long-term performance and health")
        ]
    }
}
