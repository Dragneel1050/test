//
//  SwiftUIView.swift
//  Corbo
//
//  Created by Agustín Nanni on 21/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import Lottie

struct ChatViewBottomControls: View {
    @Binding var model: ChatViewModel

    var body: some View {
        switch model.currentMode {
        case .Text:
            textModeControls(model: $model)
        case .Voice:
            voiceModeControls(model: $model)
        }
    }
}

fileprivate struct textModeControls: View {
    @Binding var model: ChatViewModel
    @State private var showLosingConfirmation = false
    @State private var keyboardPadding = CGFloat(0)

    var body: some View {
        VStack{
            HStack{
                Button{
                    Task{ @MainActor in
                        model.handleLeave()
                    }
                } label: {
                    Image("Glyph=ChatXMark")
                        .foregroundStyle(model.iconColor())
                }
                Spacer()
                Button{
                    if model.working {
                        return
                    }
                    
                    if model.textModeText.isEmpty {
                        model.startListening()
                        return
                    }
                    
                    showLosingConfirmation = true
                } label: {
                    Image("Glyph=Microphone")
                        .foregroundStyle(model.iconColor())
                }
                Spacer()
                Button{
                    if model.working {
                        return
                    }
                    
                    model.handleTextCheckmark()
                } label: {
                    ZStack{
                        Image("Glyph=ChatCheckmark")
                            .foregroundStyle(.chatPrimary)
                            .opacity(model.textModeText.isEmpty ? 0.2 : 1)
                            .disabled(model.textModeText.isEmpty)
                            .opacity(model.working ? 0 : 1)
                        ProgressView()
                            .tint(.chatPrimary)
                            .opacity(model.working ? 1 : 0)
                    }

                }
            }
            .padding(.bottom, 60)
            .padding(.bottom, keyboardPadding * 0.9)
            .padding(.horizontal, 20)
            .confirmationDialog("You will lose the text if you leave now!", isPresented: $showLosingConfirmation, titleVisibility: .visible, actions: {
                Button("Switch Modes", role: .destructive) {
                    model.startListening()
                }
                Button("Cancel", role: .cancel) {
                    showLosingConfirmation = false
                }
            })
            .onReceive(ContextualActionModel.shared.keyboardHeightPublisher, perform: { value in
                withAnimation(.easeInOut.speed(5)) {
                    keyboardPadding = value
                }
            })
        }

    }
}

fileprivate struct voiceModeControls: View {
    @Binding var model: ChatViewModel
    
    var body: some View {
        VStack(spacing: 20){
            HStack{
                Spacer()
                Button{
                    if model.working {
                        return
                    }
                    Task{ @MainActor in
                        model.handleEnableTextMode()
                    }
                } label: {
                    Image("Glyph=Keyboard")
                        .foregroundStyle(model.iconColor())
                }
                .disabled(model.messagesWorking)
                Spacer()
            }
            .padding(.horizontal, 30)
            HStack{
                Spacer()
                Button{
                    Task { @MainActor in
                        model.handleLeave()
                    }
                } label: {
                    ZStack{
                        Circle()
                            .stroke(model.iconColor(), style: StrokeStyle(lineWidth: 3))
                            .frame(width: 40)
                        Image("Glyph=ChatXMark")
                            .foregroundStyle(.chatPrimary)
                    }
                }
                Spacer()
                recordButton(model: $model)
                Spacer()
                Button{
                    Task{ @MainActor in
                        model.handleCheckmark()
                    }
                } label: {
                    ZStack{
                        Circle()
                            .stroke(model.iconColor(), style: StrokeStyle(lineWidth: 3))
                            .frame(width: 40)
                        Image("Glyph=ChatCheckmark")
                            .foregroundStyle(model.iconColor())
                    }
                }
                .disabled(model.messagesWorking)
                .opacity(model.showingCurrentStoryPreview ? 1 : 0)
                Spacer()
            }
            .padding(.bottom)
        }
    }
}

fileprivate struct recordButton: View {
    @Binding var model: ChatViewModel

    var body: some View {
        ZStack{
            Button{
                Task{ @MainActor in
                    model.handleCenterButtonTap()
                }
            } label: {
               Image("Glyph=ChatPlusIcon")
                    .foregroundStyle(.chatPrimary)
                    .frame(maxWidth: 80, maxHeight: 80)
            }
            .opacity(model.working || !model.showingCurrentStoryPreview ? 0 : 1)
                Button{
                    model.handleCenterButtonTap()
                } label: {
                    if model.recording {
                        LottieView{
                            try await DotLottieFile.named("waveform")
                        } placeholder: {
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.chatPrimary)
                        }
                        .playing(loopMode: .loop)
                        .resizable()
                        .frame(maxWidth: 80, maxHeight: 80)
                    } else {
                        Image("SpeakNav")
                    }
                }
                .opacity(model.working || model.showingCurrentStoryPreview ? 0 : 1)
                .disabled(model.showingCurrentStoryPreview || model.messagesWorking)
            LottieView{
                try await DotLottieFile.named("loadinganimation")
            } placeholder: {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.chatPrimary)
            }
            .resizable()
            .playing(loopMode: .loop)
            .frame(maxWidth: 60, maxHeight: 60)
            .opacity(model.working ? 1 : 0)
        }
    }
}

#Preview {
    ChatViewBottomControls(model: Binding.constant(
        ChatViewModel(chatViewOpen: .constant(true),
        messages: [
            ChatElement(type: .userTranscript, text: "This is a question"),
            ChatElement(type: .assistantMessage, text: "This is an answer")
        ])))
    .background{
        Background()
    }
}
