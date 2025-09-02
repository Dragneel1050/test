//
//  AnswerFeedbackView.swift
//  Corbo
//
//  Created by Agustín Nanni on 03/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct SubmitFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    let questionId: Int64
    
    @State private var text = ""
    @State private var submitting = false
    @State private var positive = true
    @State private var notTrue = false
    @State private var notHelpful = false
    @State private var isHarmful = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack{
                HStack{
                    HStack{
                        Button{
                            setPositive(true)
                        } label: {
                            ZStack{
                                Circle()
                                    .frame(width: 35)
                                    .foregroundStyle(.green)
                                Image(systemName: "hand.thumbsup")
                                    .foregroundColor(.textPrimary)
                            }
                            .opacity(positive ? 1 : 0.2)
                        }
                        Button{
                            setPositive(false)
                        } label: {
                            ZStack{
                                Circle()
                                    .frame(width: 35)
                                    .foregroundStyle(.red)
                                Image(systemName: "hand.thumbsdown")
                                    .foregroundColor(.textPrimary)
                            }
                            .opacity(!positive ? 1 : 0.2)
                        }
                    }
                    Spacer()
                    Button{
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .offset(y: -3)
                            .foregroundColor(.textPrimary)
                    }
                }
                HStack{
                    Spacer()
                    Text("Submit your feedback")
                        .font(Theme.questionsSelectionSelected)
                        .foregroundStyle(.textTitle)
                    Spacer()
                }
            }
            

            TextEditor(text: $text)
                .foregroundStyle(.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
                .background{
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                        .fill(Color.surfacePanel)
                }
                .padding()
            
                VStack{
                    if !positive{
                        Toggle(isOn: $notTrue) {
                            Text("It's not true")
                                .foregroundColor(.textPrimary)
                        }
                        Toggle(isOn: $notHelpful) {
                            Text("It's not helpful")
                                .foregroundColor(.textPrimary)
                        }
                        Toggle(isOn: $isHarmful) {
                            Text("It's harmful")
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                .tint(.chatPrimary)
                .transition(.move(edge: .bottom))
            
            
            FormButton(action: {
                do {
                    try await ApiModel.shared.submitQuestionFeedback(request: submitQuestionFeedbackRequest(questionId: questionId, feedback: text, isPositive: positive, isHarmful: isHarmful, notTrue: notTrue, notHelpful: notHelpful))
                    ToastsModel.shared.displayMessage(text: "Feedback submitted", bgColor: .green, textColor: .white)
                } catch let err {
                    
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    } else {
                        AppLogs.defaultLogger.error("SubmitFeedbackView: \(err)")
                        ToastsModel.shared.notifyError(context: String(localized: "SubmitFeedbackView.SubmitQuestionFeedback"), error: err )
                    }
                }
                
                dismiss()
            }, label: "Save feedback" )
        }
        .padding()
        .background(
            ZStack{
                Background()
                positive ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
            }
                .ignoresSafeArea()
        )
    }
    
    @MainActor
    func setPositive(_ value: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            positive = value
        }
    }
}

struct SubmitFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitFeedbackView(questionId: 1)
    }
}
