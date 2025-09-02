//

import SwiftUI

enum widthVariants{
    case normal, wide, content
    
    var value: CGFloat? {
        switch self {
            case .normal:
                210
            case .wide:
                280
            case .content:
                nil
        }
    }
}

enum heightVariants{
    case small, normal, content
    
    var value: CGFloat? {
        switch self {
            case .small:
                130
            case .normal:
                180
            case .content:
                nil
        }
    }
}

struct Card<Content: View>: View {
    let id = UUID()
    let content: Content
    
    init(width: widthVariants = .normal, height: heightVariants = .normal, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.width = width.value
        self.height = height.value
    }
    
    private var width: CGFloat?
    private var height: CGFloat?
    @State private var bgHeight = CGFloat.zero
    
    var body: some View {
        self.content
            .padding(8)
            .frame(width: width, height: height)
            .background{
                GeometryReader{ geo in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.surfacePanel)
                        .overlay{
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.borderPrimary, style: StrokeStyle())
                        }
                        .onAppear{
                            bgHeight = geo.size.height
                        }
                }
            }
    }
    
}

struct CardAction {
    let action: () async -> Void
    let background: Color
    let icon: Image
}

struct ActivityIndicatorCard: View {
    let width: widthVariants
    let height: heightVariants
    
    @State var animate = false
    
    var body: some View {
        Card(width: width, height: height) {
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
                    .frame(height: 40)
            }
        }
        .opacity(animate ? 0.4 : 1)
        .transition(.opacity)
        .animation(.easeInOut.repeatForever(autoreverses: true), value: animate)
        .onAppear{
            animate = true
        }
    }
}

struct ActivityIndicatorCards: View {
    var body: some View {
        ForEach((1...10), id: \.self) { _ in
            ActivityIndicatorCard(width: .content, height: .content)
        }
    }
}

#Preview {
    VStack{
        Card() {
            VStack{
                Text("Hello, World!")
                    .foregroundStyle(.white)
                Text("Hello, World!")
                    .foregroundStyle(.white)
                Text("Hello, World!")
                    .foregroundStyle(.white)
                HStack{
                    Text("Hello, World!")
                        .foregroundStyle(.white)
                    Text("Hello, World!")
                        .foregroundStyle(.white)
                }
            }
        }
        ActivityIndicatorCard(width: .normal, height: .normal)
    }
}


#Preview {
    ScrollView {
        VStack{
            Card() {
                VStack{
                    Text("Hello, World!")
                        .foregroundStyle(.white)
                    Text("Hello, World!")
                        .foregroundStyle(.white)
                    Text("Hello, World!Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.")
                        .foregroundStyle(.white)
                    HStack{
                        Text("Hello, World!")
                            .foregroundStyle(.white)
                        Text("Hello, World!")
                            .foregroundStyle(.white)
                    }
                }
            }
            Card(width: .content, height: .content) {
                VStack{
                    Text("Hello, World!")
                        .foregroundStyle(.white)
                    Text("Hello, World! Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.")
                        .foregroundStyle(.white)
                    Text("Hello, World! Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.")
                        .foregroundStyle(.white)
                    HStack{
                        Text("Hello, World!")
                            .foregroundStyle(.white)
                        Text("Hello, World! Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.")
                            .foregroundStyle(.white)
                    }
                }
            }
            ActivityIndicatorCard(width: .content, height: .content)
        }
    }
}

#Preview {
    VStack{
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "My best friend John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.blue
            }
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 57786, content: "The other day, I went with my friends to a bar and we had like the most fun ever.And also, uh, we ate some pizza that was... Wow.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.blue
            }
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "Today I went with my friends to a bar and we had a lot of fun.We also ate some pizza, and it was great.And there were video games in the bar, so they were awesome.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.blue
            }
        Card(width: .content){
            Text("My best friend John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.")
                .foregroundStyle(.red)
        }
    }

}
