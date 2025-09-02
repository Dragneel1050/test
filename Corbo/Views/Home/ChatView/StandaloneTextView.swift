//
//  StandaloneTextView.swift
//  Corbo
//
//  Created by Agustín Nanni on 29/05/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct StandaloneTextView: View {
    private let doExit: () -> Void
    @State private var text: String
    @State private var working = false
    @State private var keyboardHeight = CGFloat(0)
    @FocusState private var focus
    @State private var keyboardPublisher =
    NotificationCenter.default
    .publisher(for: UIResponder.keyboardWillShowNotification)
    .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
    .map { $0.cgRectValue.height }
    .eraseToAnyPublisher()
    
    init(text: String, doExit: @escaping () -> Void) {
        self._text = State(initialValue: text)
        self.doExit = doExit
    }
    
    var body: some View {
        GeometryReader{ geo in
            VStack{
                ScrollView(showsIndicators: false) {
                    VStack{
                        ChatBubble(text: "StandaloneTextView.Prompt", variant: .assistant)
                        TextField("", text: $text, axis: .vertical)
                            .font(Theme.chatTextTranscript)
                            .foregroundStyle(working ? Color.chatTextThinking : Color.chatTextTranscript )
                            .focused($focus)
                            .onAppear{
                                self.focus = true
                            }
                    }
                    .padding(.horizontal, 20)
                }
                HStack{
                    Button{
                        if working {
                            return
                        }
                        self.doExit()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.chatPrimary)
                    }
                    Spacer()
                    Button{
                        if working {
                            return
                        }
                        self.handlePaste()
                    } label: {
                        Image("Glyph=Paste")
                            .foregroundStyle(.chatPrimary)
                    }
                    Spacer()
                    Button{
                        if working {
                            return
                        }
                        
                        Task {
                            await handleSubmit()
                        }
                    } label: {
                        ZStack{
                            Image("Glyph=Checkmark")
                                .foregroundStyle(.chatPrimary)
                                .opacity(working ? 0 : 1)
                            ProgressView()
                                .tint(.chatPrimary)
                                .opacity(working ? 1 : 0)
                        }

                    }
                }
                .padding(.bottom, keyboardHeight)
                .padding(.horizontal, 30)
            }
            .padding(.top)
            .ignoresSafeArea(.keyboard)
            .onReceive(keyboardPublisher, perform: { self.keyboardHeight = $0})
            .background{
                ChatPanelBorderText(globalBounds: geo.frame(in: .local))
                    .stroke(.chatPrimary, style: StrokeStyle(lineWidth: 3, lineJoin: .miter))
            }
        }
    }
    
    func handlePaste() {
        let pasteboard = UIPasteboard.general
        if let text = pasteboard.string {
            self.text += text
        }
    }
    
    func handleSubmit() async {
        working = true
        do {
            let _ = try await StoriesModel.shared.createStory(text, location: LocationModel.shared.getLastLocation(), sessionId: nil, inChat: false)
            EventsModel.shared.track(StoryCreated(source: "Share extension"))
            doExit()
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                ToastsModel.shared.notifyError(context: "StandaloneTextView.handleSubmit()", error: err)
                AppLogs.defaultLogger.error("handleSubmit: \(err)")
            }
        }
        working = false
    }
}

#Preview {
    ZStack {
        Background()
        StandaloneTextView(text: "asdaasddasdas", doExit: {})
    }
}
