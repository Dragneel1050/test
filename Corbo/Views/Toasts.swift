//

import SwiftUI

struct Toasts<Content: View>: View where Content: View {
    var font: Font = Theme.toastText
    var content: () -> Content
    @Binding var state: ToastState
    @State private var yOffset = CGFloat(0)
    
    init(
        state: Binding<ToastState>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._state = state
        self.content = content
    }
    
    func clearAndHide() -> Void {
        withAnimation{
            state.text = nil
            state.backgroundColor = .red
            state.textColor = .white
        }
    }
    
    func autoHide() async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        clearAndHide()
    }
    
    var body: some View {
        VStack(content: content).overlay(alignment: .topLeading) {
            VStack{
                Spacer()
                    .frame(height:40)
                if state.text != nil {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(state.backgroundColor)
                            .frame(height: 50)
                            .padding()
                            .shadow(color: .gray.opacity(0.7), radius: 20)
                        HStack {
                            Text(state.text != nil ? state.text! : "")
                                .padding(.leading, 30)
                                .foregroundColor(state.textColor)
                                .font(font)
                            Spacer()
                            Button(action: {clearAndHide()}) {
                                Image(systemName: "x.circle")
                                    .foregroundColor(state.textColor)
                                    .padding(.trailing, 25)
                            }
                        }
                    }
                    .offset(y: yOffset)
                    .transition(.offset(y: -250))
                    .task{
                        await autoHide()
                    }
                }
                Spacer()
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading)
            .ignoresSafeArea(.all)
        }
    }
}

struct ToastsDefaultPreview: View {
    @State var state = ToastState()
    
    func fireMessageUp() -> Void {
        withAnimation{
            self.state.text = "Whoops! Something went wrong"
        }
    }
    
    var body: some View {
        Toasts(state: $state) {
            VStack{
                Color.white
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
                Button("Show message", action: {fireMessageUp()})
            }
        }
    }
}


#Preview {
    ToastsDefaultPreview()
}

@Observable
public class ToastState{
    var text: String? = nil
    var backgroundColor: Color = .red
    var textColor: Color = .white
}
