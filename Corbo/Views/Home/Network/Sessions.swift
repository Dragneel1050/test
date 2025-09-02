//

import SwiftUI

struct Sessions: View {
    @State private var model = NetworkViewModel.shared
    
    var body: some View {
        VStack{
            TopNav(variant: .network, leftAction: {}, rightAction: {})
                .padding(.horizontal)
            VStack(spacing: 20){
                header()
                    .padding(.horizontal)
                RecentSessions(model: $model)
            }
        }
    }
    
    func header() -> some View {
        VStack(alignment: .leading){
            HStack{Spacer()}
            let firstName = AuthModel.shared.currentUserData?.firstName ?? "FirstName"
            Text("Hi \(firstName)")
                .font(Theme.textHeaderNetwork)
                .foregroundStyle(Color.textHeader)
            Text("Let’s get you connected.")
                .font(Theme.textTitle)
                .foregroundStyle(Color.textTitle)
        }
    }
    
    func networkUpdatesPreview() -> some View {
        VStack(alignment: .leading){
            Text("Network Updates")
                .font(Theme.textHeader)
                .foregroundStyle(Color.textHeader)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack{
                    Card(width: .wide){
                        IntroRequestCardBody()
                    }
                    Card(width: .wide) {
                        ContactsFoundCardBody()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

fileprivate struct RecentSessions: View {
    @Binding var model: NetworkViewModel
    @State private var homeModel = HomeModel.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            Text("Recent Sessions")
                .font(Theme.textHeader)
                .foregroundStyle(Color.textHeader)
                .padding(.horizontal)
            
            ScrollView(.vertical) {
                LazyVStack{
                    if let list = model.sessionList {
                        if list.isEmpty {
                            emptySessionState()
                        } else {
                            ForEach(list, id: \.id) { session in
                                sessionCard(session)
                            }
                        }
                    } else {
                        ActivityIndicatorCards()
                        .task{
                            await model.findListSessionResponse()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    func emptySessionState() -> some View {
        VStack{
            HStack{
                Text("No recent sessions")
                    .foregroundStyle(Color.textSecondary)
                    .font(.system(size: 16))
                    .italic()
                Spacer()
            }
            .padding(.vertical)
            
            Card(width: .content, height: .content){
                VStack(alignment: .leading, spacing: 15){
                    Text("Getting Started")
                        .font(Theme.title)
                        .foregroundStyle(.textPrimary)
                    AppDivider()
                    (Text("Create Stories").foregroundStyle(Color.textPrimary) + Text(" to capture important info about colleagues, events, and opportunities").foregroundStyle(Color.textSecondary))
                        .font(Theme.instructionCard)
                    AppDivider()
                    (Text("Ask Questions").foregroundStyle(Color.textPrimary) + Text(" to recall details and summarize insights from all your Stories and Contacts").foregroundStyle(Color.textSecondary))
                        .font(Theme.instructionCard)
                    AppDivider()
                    HStack{
                        Image("SpeakNav")
                        (Text("The Chat Button").foregroundStyle(Color.textPrimary) + Text(" unlocks the power of Corbo.").foregroundStyle(Color.textSecondary))
                            .font(Theme.instructionCard)
                    }
                    Text("Just tap it, then begin speaking to create a Story or Ask a question. You can also tap the Keyboard to chat via text.")
                        .font(Theme.instructionCard)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    func sessionCard(_ session: Session) -> some View {
        Button{
            Task{ @MainActor in
                if session.id != nil {
                    model.openSession(session, chatViewOpen: $homeModel.chatViewOpen)
                }
            }
        } label: {
            Card(width: .content, height: .content) {
                HStack{
                    VStack(alignment: .leading){
                        Text(.init(sessionTitle(session)))
                            .foregroundStyle(.textPrimary)
                            .font(Theme.condensedLight)
                            .minimumScaleFactor(0.01)
                            .multilineTextAlignment(.leading)
                        
                        HStack{
                            Text("Created: \(session.createdTime!.formatted())")
                                .foregroundStyle(.textPrimary)
                                .font(Theme.condensedLightCaption)
                                .minimumScaleFactor(0.01)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    func sessionTitle(_ session: Session) -> String {
        guard let title = session.title else {
            return ""
        }
        
        let maxWords = 10
        let split = title.split(separator: " ")
        
        if split.count > maxWords {
            return split[0...maxWords].joined(separator: " ") + "..."
        } else {
            return title
        }
    }
}

fileprivate struct IntroRequestCardBody: View {
    var body: some View {
        VStack{
            HStack{
                Text("Intro Request")
                    .font(Theme.barlowLight)
                    .foregroundStyle(.iconPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.iconPrimary)
                    .font(.system(size: 25).weight(.light))
            }
            Divider()
                .background{Color.borderPrimary}
            Spacer()
            Group{
                Text("Jill Wilson")
                    .foregroundStyle(.textEntity)
                + Text(" is looking for a designer who has motion / 3D experience for immediate freelance opportunity.")
                    .foregroundStyle(.textPrimary)
            }
            .padding(2)
            .font(Theme.condensedLight)
            .minimumScaleFactor(0.01)
            .multilineTextAlignment(.center)
            .frame(alignment: .top)
            Spacer()
            
            PreviewIndicator()
        }
    }
}

fileprivate struct ContactsFoundCardBody: View {
    var body: some View {
        VStack{
            HStack{
                Text("2 Contacts found")
                    .font(Theme.barlowLight)
                    .foregroundStyle(.iconPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.iconPrimary)
                    .font(.system(size: 25).weight(.light))
            }
            Divider()
                .background{Color.borderPrimary}
            Spacer()
            Group{
                Text("Brandy Burt, Merlin Floyd")
                    .foregroundStyle(.textEntity)
                + Text(" in your recent Stories")
                    .foregroundStyle(.textPrimary)
            }
            .padding(2)
            .font(Theme.condensedLight)
            .minimumScaleFactor(0.01)
            .multilineTextAlignment(.center)
            .frame(alignment: .top)
            Spacer()
            PreviewIndicator()
        }
    }
}


#Preview {
    Sessions()
        .background(Background())
}

#Preview{
    VStack{
        RecentSessions(model: .constant(NetworkViewModel(listSessionsResponse: listSessionResponse(sessionList: [Session(id: 1, userAccountId: 1, title: "This is a test", createdTime: Date.now),
        Session(id: 2, userAccountId: 1, title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sodales. Quisque sodales.", createdTime: Date.now)]))))
    }
    .background{
        Background()
    }
}
