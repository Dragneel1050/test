//

import SwiftUI

struct FormTextInput: View {
    let placeholder: String?
    @Binding var text: String
    @FocusState var focus: Bool
    
    init(placeholder: String? = nil, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        ZStack{
            TextField("", text: $text)
                .foregroundStyle(Color.textPrimary)
                .padding()
                .focused($focus)
                .background{
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .fill(Color.surfaceFormControl)
                        .stroke(Color.borderForm, lineWidth: 1)
            }
            HStack{
                if let placeholder = placeholder {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(Theme.formPlaceHolder)
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .onTapGesture {
            focus = true
        }
    }
}

#Preview {
    FormTextInput(placeholder: "Hello world!", text: .constant(""))
}
