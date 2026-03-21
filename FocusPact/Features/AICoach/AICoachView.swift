import SwiftUI
import SwiftUI

struct AICoachView: View {
    @EnvironmentObject private var aiService: AICoachService
    @StateObject private var vm: AICoachViewModel
    @State private var scrollProxy: ScrollViewProxy? = nil

    init(aiService: AICoachService) {
        _vm = StateObject(wrappedValue: AICoachViewModel(aiService: aiService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                inputBar
            }
            .background(Color.fpBackground)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    prebuiltPromptButtons
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 12) {
                        ForEach(vm.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if vm.isSending {
                            TypingIndicator()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: vm.messages.count) { _, _ in
                if let lastId = vm.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
            }
        }
    }

    private var prebuiltPromptButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PrebuiltPrompt.allCases, id: \.rawValue) { prompt in
                    Button {
                        Task { await vm.sendPrebuiltPrompt(prompt) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 13))
                            Text(prompt.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.fpPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.fpPrimary.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.fpPrimary.opacity(0.3), lineWidth: 1))
                    }
                    .disabled(vm.isSending)
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.fpBorder)

            HStack(spacing: 12) {
                TextField("Ask your AI coach...", text: $vm.inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.fpTextPrimary)
                    .tint(Color.fpPrimary)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.fpSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.fpBorder, lineWidth: 1))

                Button {
                    let text = vm.inputText
                    Task { await vm.sendMessage(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending
                            ? Color.fpTextSecondary
                            : Color.fpPrimary
                        )
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.fpBackground)
        }
    }
}

// MARK: - ChatBubble

private struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient.fpPrimaryGradient)
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundStyle(isUser ? .white : Color.fpTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                        ? LinearGradient.fpPrimaryGradient
                        : LinearGradient(colors: [Color.fpSurface], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        isUser ? nil : RoundedRectangle(cornerRadius: 18).stroke(Color.fpBorder, lineWidth: 1)
                    )

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fpTextSecondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient.fpPrimaryGradient)
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.fpTextSecondary)
                        .frame(width: 7, height: 7)
                        .offset(y: animating ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.fpSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.fpBorder, lineWidth: 1))

            Spacer(minLength: 60)
        }
        .onAppear { animating = true }
    }
}
