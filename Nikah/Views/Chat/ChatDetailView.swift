// Views/Chat/ChatDetailView.swift

import SwiftUI
import AVFoundation

struct ChatDetailView: View {
    let match: MatchModel
    let otherUser: UserModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var chatVM = ChatViewModel()
    @State private var messageText: String = ""
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var isRecording = false
    @State private var isUploadingVoice = false
    @State private var voiceErrorMessage: String?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if AppConstants.strictGuardianOnlyCommunication {
                guardianOnlyView
            } else {
            // MARK: Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatVM.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authVM.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatVM.messages.count) {
                    if let lastId = chatVM.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // MARK: Input Bar
            HStack(spacing: 10) {
                Button {
                    handleMicTap()
                } label: {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isRecording ? .white : .nikahMaroon)
                        .frame(width: 38, height: 38)
                        .background(isRecording ? Color.red : Color.nikahCream)
                        .clipShape(Circle())
                }
                .disabled(isUploadingVoice)

                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .disabled(isRecording || isUploadingVoice)

                if isUploadingVoice {
                    ProgressView()
                        .frame(width: 42, height: 42)
                }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(messageText.trimmed.isEmpty ? Color(.systemGray4) : Color.nikahGreen)
                        .clipShape(Circle())
                }
                    .disabled(messageText.trimmed.isEmpty || isRecording || isUploadingVoice)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            }
        }
        .navigationTitle(otherUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileDetailView(user: otherUser)
                        .environmentObject(authVM)
                } label: {
                    Group {
                        if let url = otherUser.firstPhoto.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color(.systemGray4)
                                }
                            }
                        } else {
                            Color(.systemGray4)
                        }
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                }
            }
        }
        .onAppear {
            if let matchId = match.id {
                chatVM.startListeningToMessages(matchId: matchId)
            }
        }
        .alert("Voice Note Error", isPresented: Binding(
            get: { voiceErrorMessage != nil },
            set: { if !$0 { voiceErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(voiceErrorMessage ?? "Unknown error")
        }
        .onDisappear {
            stopRecording(cleanupOnly: true)
            chatVM.stopListening()
        }
    }

    private func sendMessage() {
        guard let matchId = match.id,
              let senderId = authVM.currentUser?.id else { return }
        chatVM.sendMessage(matchId: matchId, senderId: senderId, text: messageText)
        messageText = ""
    }

    private var guardianOnlyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 54))
                .foregroundColor(.nikahGreen)
                .padding(.top, 20)

            Text("Guardian-Only Communication")
                .font(.title3)
                .fontWeight(.bold)

            Text("Direct chat is disabled to maintain a Sharia-compliant flow. Please contact the guardian/wali first.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                HStack {
                    Text("Guardian")
                    Spacer()
                    Text(otherUser.guardianName.isEmpty ? "Not provided" : otherUser.guardianName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Contact")
                    Spacer()
                    Text(otherUser.guardianContact.isEmpty ? "Not provided" : otherUser.guardianContact)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)

            if !otherUser.guardianContact.isEmpty {
                Button {
                    let phone = otherUser.guardianContact.filter { "0123456789+".contains($0) }
                    if let url = URL(string: "tel://\(phone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Contact Guardian", systemImage: "phone.fill")
                        .nikahButton()
                        .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
    }

    private func handleMicTap() {
        if isRecording {
            stopRecording(cleanupOnly: false)
            uploadRecordedVoiceIfAvailable()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    voiceErrorMessage = "Microphone permission denied. Please enable it in Settings."
                    return
                }

                do {
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try session.setActive(true)

                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("voice-note-\(UUID().uuidString).m4a")

                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]

                    let recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder.record()

                    audioRecorder = recorder
                    recordingURL = url
                    isRecording = true
                } catch {
                    voiceErrorMessage = "Could not start recording."
                }
            }
        }
    }

    private func stopRecording(cleanupOnly: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        if cleanupOnly {
            recordingURL = nil
        }
    }

    private func uploadRecordedVoiceIfAvailable() {
        guard let matchId = match.id,
              let senderId = authVM.currentUser?.id,
              let url = recordingURL else {
            voiceErrorMessage = "Recording unavailable. Please try again."
            return
        }

        isUploadingVoice = true
        chatVM.sendVoiceMessage(matchId: matchId, senderId: senderId, fileURL: url) { success in
            DispatchQueue.main.async {
                isUploadingVoice = false
                if success {
                    try? FileManager.default.removeItem(at: url)
                } else {
                    voiceErrorMessage = "Failed to send voice note."
                }
                recordingURL = nil
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: MessageModel
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if message.messageType == "voice", let audioURL = message.audioURL {
                    VoiceMessageBubble(
                        audioURL: audioURL,
                        duration: message.audioDuration,
                        isFromCurrentUser: isFromCurrentUser
                    )
                } else {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isFromCurrentUser ? Color.nikahGreen : Color(.systemGray5))
                        .cornerRadius(18, corners: isFromCurrentUser
                            ? [.topLeft, .topRight, .bottomLeft]
                            : [.topLeft, .topRight, .bottomRight]
                        )
                }

                Text(message.timestamp.timeAgoDisplay)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}

private struct VoiceMessageBubble: View {
    let audioURL: String
    let duration: Double?
    let isFromCurrentUser: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        Button {
            togglePlay()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                Text(durationText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isFromCurrentUser ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isFromCurrentUser ? Color.nikahGreen : Color(.systemGray5))
            .cornerRadius(18, corners: isFromCurrentUser
                ? [.topLeft, .topRight, .bottomLeft]
                : [.topLeft, .topRight, .bottomRight]
            )
        }
        .buttonStyle(.plain)
    }

    private var durationText: String {
        guard let duration, duration.isFinite else { return "Voice note" }
        return String(format: "%.0fs", max(1, duration))
    }

    private func togglePlay() {
        guard let url = URL(string: audioURL) else { return }

        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        if player == nil {
            player = AVPlayer(url: url)
        }

        player?.play()
        isPlaying = true
    }
}
