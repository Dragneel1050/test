//

import SwiftUI

struct Stories: View {
    @State private var model = StoriesModel.shared
    
    var body: some View {
        VStack{
            TopNav(variant: .stories, leftAction: {}, rightAction: {})
                .padding(.horizontal)
            VStack(spacing: 30){
                RecentStories(model: $model)
                    .onAppear(perform: model.prepareStoriesView )
            }
        }
    }
    
    func suggestedTasksPreview() -> some View {
        VStack(alignment: .leading){
            Text("Suggested tasks")
                .font(Theme.textHeader)
                .foregroundStyle(Color.textHeader)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack{
                    Card(width: .normal, height: .small){
                        FineTuningCardBody()
                    }
                    Card(width: .normal, height: .small) {
                        EventSuggestionCardBody()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

fileprivate struct FineTuningCardBody: View {
    var body: some View {
        VStack{
            HStack(alignment: .top){
                Group{
                    Text("You created \n")
                        .foregroundStyle(.textPrimary)
                        .font(Theme.textStoriesSuggested)
                    + Text("2 new stories \n")
                        .foregroundStyle(.textPrimary)
                        .font(Theme.textStoriesSuggestedMedium)
                    + Text("you could fine tune.")
                        .foregroundStyle(.textPrimary)
                        .font(Theme.textStoriesSuggested)
                }
                .minimumScaleFactor(0.01)
                .multilineTextAlignment(.leading)
                .frame(alignment: .top)
                Spacer()
                Image("Glyph=Stories")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20)
                    .foregroundStyle(.iconPrimary)
                    .padding(5)
                    .background{
                        Circle()
                            .fill(.buttonDefault)
                    }
            }
            Spacer()
            HStack{
                Text("Review now")
                    .foregroundStyle(.textPrimary)
                    .font(Theme.textStoriesSuggested)
                Spacer()
                Image("Glyph=ArrowForward")
                    .foregroundStyle(.textPrimary)
            }
            PreviewIndicator()
        }
    }
}

fileprivate struct EventSuggestionCardBody: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            Group{
                Text("Do you want to add a story for:")
                    .foregroundStyle(.textPrimary)
                    .font(Theme.textStoriesSuggested)
                
                Text("Lunch at Cafe Mogul")
                    .foregroundStyle(.textPrimary)
                    .font(Theme.textStoriesSuggestedMedium)
            }
            .minimumScaleFactor(0.01)
            .multilineTextAlignment(.leading)
            .frame(alignment: .top)
            Spacer()
            HStack{
                Text("Add a story")
                    .foregroundStyle(.textHeader)
                    .font(Theme.textStoriesSuggested)
                Spacer()
            }
            PreviewIndicator()
        }
    }
}


fileprivate struct RecentStories: View {
    @Binding var model: StoriesModel
    
    enum selectedTab: CaseIterable{
        case recentlyCreated
        //case synced, received
        
        var text: String {
            switch self {
                case .recentlyCreated:
                    "Recent"
                /*
                case .synced:
                    "Synced (3)"
                case .received:
                    "Recieved"
                 */
            }
        }
    }
    
    @State private var currentTab = selectedTab.recentlyCreated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 25){
                    ForEach(selectedTab.allCases, id: \.self) { tab in
                        tabOption(tab)
                    }
                }
                .padding(.horizontal, 25)
            }
            
            ScrollView(.vertical) {
                LazyVStack{
                    if let list = model.storiesList {
                        if list.isEmpty {
                            VStack(alignment: .center){
                                HStack{Spacer()}
                                Spacer()
                                Text("There are no stories yet. Try creating a new story...")
                                    .foregroundStyle(.textPrimary)
                                    .font(Theme.textStoriesSuggested)
                                Spacer()
                            }
                        } else {
                            ForEach(list, id: \.id) { story in
                                Button{
                                    HomeModel.shared.homeNavPath.append(story)
                                } label: {
                                    StoryCard(storyWithEntities: story)
                                }
                            }
                        }
                    } else {
                        ActivityIndicatorCards()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    func tabOption(_ tab: selectedTab) -> some View {
        let font = currentTab == tab ? Theme.questionsSelectionSelected : Theme.questionsSelectionSecondary
        let color = currentTab == tab ? Color.textPrimary : Color.textHeader
        return Button{
            currentTab = tab
        } label: {
            Text(tab.text)
                .font(font)
                .foregroundStyle(color)
                .underline(currentTab == tab)
        }
    }
}



#Preview {
    Stories()
        .background(Background())
}
