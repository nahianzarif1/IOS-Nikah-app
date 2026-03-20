// Views/Feed/ProfileCardView.swift

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct ProfileCardView: View {
    let user: UserModel
    let onLike: () -> Void
    let onPass: () -> Void
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0

    var body: some View {
        ZStack {
            // MARK: Card Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)

            VStack(spacing: 0) {
                // MARK: Photo
                photoView
                    .frame(height: 420)
                    .clipped()
                    .cornerRadius(24, corners: [.topLeft, .topRight])

                // MARK: Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(user.displayName)
                            .font(.system(size: 22, weight: .bold))
                        Text(", \(user.age)")
                            .font(.system(size: 20, weight: .light))
                        Spacer()
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }

                    Label(user.district, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label(user.profession, systemImage: "briefcase.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // MARK: Action Buttons
                    HStack(spacing: 20) {
                        // Pass button
                        Button(action: { triggerPass() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                Text("✕")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        // Detail button
                        Button {
                            showDetail = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()

                        // Like button
                        Button(action: { triggerLike() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.nikahGreen.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                Text("❤️")
                                    .font(.system(size: 28))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .rotationEffect(.degrees(cardRotation))
        .offset(dragOffset)
        .gesture(dragGesture)
        .overlay(swipeIndicatorOverlay)
        .navigationDestination(isPresented: $showDetail) {
            ProfileDetailView(user: user)
        }
    }

    // MARK: - Photo View
    private var photoView: some View {
        Group {
            if let photoUrl = user.firstPhoto, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    case .empty:
                        Color(.systemGray5)
                            .overlay(ProgressView())
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Color(.systemGray5)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)
            )
    }

    // MARK: - Swipe Overlay
    @ViewBuilder
    private var swipeIndicatorOverlay: some View {
        if dragOffset.width > 40 {
            VStack {
                HStack {
                    Spacer()
                    Text("LIKE")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 3))
                        .rotationEffect(.degrees(-15))
                        .padding(20)
                }
                Spacer()
            }
        } else if dragOffset.width < -40 {
            VStack {
                HStack {
                    Text("PASS")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.red)
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 3))
                        .rotationEffect(.degrees(15))
                        .padding(20)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                cardRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if value.translation.width > threshold {
                    triggerLike()
                } else if value.translation.width < -threshold {
                    triggerPass()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        cardRotation = 0
                    }
                }
            }
    }

    private func triggerLike() {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onLike()
        }
    }

    private func triggerPass() {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onPass()
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
