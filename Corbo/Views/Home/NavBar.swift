//

import SwiftUI

enum availableTabs {
    case network, stories
    
    var image: String {
        switch self {
            case .network:
                return "Glyph=Network"
            case .stories:
                return "Glyph=Stories"
        }
    }
}

struct NavBar: View {
    @Binding var activeTab: availableTabs
    @State var homeModel = HomeModel.shared
    let onTap: (() -> Void)?
    
    init(activeTab: Binding<availableTabs>, onTap: (() -> Void)? = nil) {
        self._activeTab = activeTab
        self.onTap = onTap
    }
    
    var body: some View {
        VStack{
            ZStack(alignment: .bottom){
                HStack{
                    NavBarItem(item: .network, activeTab: $activeTab, onTap: onTap)
                    Spacer()
                    NavBarCenter(action: {
                        HomeModel.shared.openChatView(chatViewOpen: $homeModel.chatViewOpen)
                    })
                        .offset(y: -10)
                        .opacity(homeModel.chatViewOpen ? 0 : 1)
                    Spacer()
                    NavBarItem(item: .stories, activeTab: $activeTab, onTap: onTap)
                }
                .padding(.horizontal, 50)
                .background{
                    Color.surfaceNav
                }
            }
        }
        .opacity(homeModel.chatViewOpen ? 0.2 : 1)
        .disabled(homeModel.chatViewOpen)
    }
}

fileprivate struct NavBarCenter: View {
    @State private var imageFrame: CGRect = .zero
    let action: () -> Void
    
    var body: some View {
        ZStack{
            Circle()
                .frame(width: 90)
                .foregroundStyle(.surfaceNav)
            Button{
                action()
            } label: {
                ZStack{
                    Image("SpeakNav")
                        .background{
                            GeometryReader{ geo in
                                Color.clear.onAppear{
                                    imageFrame = geo.frame(in: .global)
                                }
                            }
                        }
                    
                    Circle()
                        .stroke(Color.chatPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .miter))
                        .frame(width: imageFrame.width * 0.85)
                        .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds, transform: {$0})
                }
                
            }
        }
    }
}

fileprivate struct NavBarItem: View {
    let item: availableTabs
    let onTap: (() -> Void)?
    @Binding var activeTab: availableTabs
    
    init(item: availableTabs, activeTab: Binding<availableTabs>, onTap: (() -> Void)? = nil) {
        self.item = item
        self.onTap = onTap
        self._activeTab = activeTab
    }
    
    var body: some View {
        Button{
            if !isActive() {
                activeTab = item
            }
            if let onTap {
                onTap()
            }
        } label: {
            VStack{
                Image(item.image)
                    .foregroundStyle(isActive() ? Color.iconPrimary : Color.iconDisabled)
                
                Circle()
                    .frame(width: 5)
                    .foregroundStyle(Color.iconPrimary)
                    .opacity(isActive() ? 1 : 0)
            }
        }
    }
    
    func isActive() -> Bool {
        return activeTab == item
    }
}
#Preview {
    NavBar(activeTab: .constant(.network))
        .ignoresSafeArea(.all)
}
