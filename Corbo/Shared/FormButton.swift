//

import SwiftUI

struct FormButton: View {
    let label: String
    let action: () async -> Void
    let variant: buttonVariants
    @Binding var working: Bool
    
    enum buttonVariants {
        case primary, secondary
    }
    
    init(action: @escaping () async -> Void, label: String, working: Binding<Bool>? = nil, variant: buttonVariants = .primary) {
        self.action = action
        self.label = label
        self.variant = variant
        
        let workingBinding = {
            if working != nil {
                return working!
            } else {
                return .constant(false)
            }
        }()
        self._working = workingBinding
    }
    
    var body: some View {
        Button(action: {
            working = true
            Task{
                await action()
                working = false
            }
        }, label: {
            ZStack{
                Text(label)
                    .font(Theme.buttonText)
                    .foregroundStyle(textColor())
                    .opacity(working ? 0 : 1)
                ProgressView()
                    .tint(textColor())
                    .opacity(working ? 1 : 0)
            }
            .frame(minWidth: 150)
            .padding()
            .background{
                RoundedRectangle(cornerRadius: 12)
                    .fill(fillColor())
                    .stroke(strokeColor())
            }
        })
        .disabled(working)
    }
    
    
    func textColor() -> Color {
        switch self.variant {
            case .primary:
                return .textButton
            case .secondary:
                return .textButtonSecondary
        }
    }
    
    func fillColor() -> Color {
        switch self.variant {
            case .primary:
                return .surfaceButton
            case .secondary:
                return .clear
        }
    }
    
    func strokeColor() -> Color {
        switch self.variant {
            case .primary:
                return .clear
            case .secondary:
                return .borderFormFocus
        }
    }
}

#Preview {
    VStack{
        HStack{
            Spacer()
        }
        Spacer()
        FormButton(action: {}, label: "Tap me!", working: .constant(false))
        FormButton(action: {}, label: "Tap me!", working: .constant(false), variant: .secondary)
        Spacer()
    }
    .background{
        Background()
    }
}
