//

import SwiftUI

enum TopNavVariants {
    case network, stories, story
    
    var text: String {
        switch self {
            case .network:
                "CORBO"
            case .stories:
                "STORIES"
            case .story:
                "STORY"
        }
    }
}

struct TopNav: View {
    let variant: TopNavVariants
    let leftAction: () -> Void
    let rightAction: () -> Void
    
    @State private var showContextMenu = false
    
    init(variant: TopNavVariants, leftAction: @escaping () -> Void, rightAction: @escaping () -> Void) {
        self.variant = variant
        self.leftAction = leftAction
        self.rightAction = rightAction
    }
    
    var body: some View {
        ZStack{
            HStack{
                topNavButton(iconName: "Glyph=Hamburger") {
                    HomeModel.shared.showSettings = true
                }
                Spacer()
            }
            HStack{
                Spacer()
                Text(variant.text)
                    .foregroundStyle(.textTitle)
                    .font(Theme.textTitle)
                Spacer()
            }
            HStack{
                Spacer()
                topNavButton(iconName: "Glyph=User") {
                    HomeModel.shared.enqueuePermissionRequest(.userData)
                    HomeModel.shared.setNextEnqueuedPermission()
                }
            }
        }
        .padding()
    }
}

struct topNavButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            ZStack{
                Image(iconName)
                    .foregroundStyle(.iconPrimary)
                Circle()
                    .stroke(Color.borderPrimary, style: StrokeStyle())
                    .frame(width: 40)
            }
        })
    }
}

#Preview {
    TopNav(variant: .network, leftAction: {}, rightAction: {})
        .background(Color.surfaceApp)
}
