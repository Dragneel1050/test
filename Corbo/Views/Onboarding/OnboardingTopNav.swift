//

import SwiftUI

struct OnboardingTopNav: View {
    let onBack: (() -> Void)?
    
    init (onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack{
            HStack{
                if let onBack = onBack {
                    Button(action: onBack, label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundStyle(.textTitle)
                    })
                }
                Spacer()
            }
            HStack {
                Spacer()
                Text("CORBO")
                    .font(Theme.barlowRegular)
                    .foregroundStyle(.textTitle)
                Spacer()
            }
        }
        .padding(.top)
        .padding(.horizontal, 30)
    }
}

#Preview {
    OnboardingTopNav(onBack: {})
}
