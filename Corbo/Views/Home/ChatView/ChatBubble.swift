//
import SwiftUI
import Combine

enum ChatBubbleVariants {
    case assistant, user
    
    var direction: bubbleDirection {
        switch self {
            case .assistant:
                    .left
            case .user:
                    .right
        }
    }
    
    var fillColor: Color {
        switch self {
            case .assistant:
                    .chatSurfaceThinking
            case .user:
                    .chatPrimary
        }
    }
    
    var textColor: Color {
        switch self {
            case .assistant:
                    .chatTextThinking
            case .user:
                    .chatTextBot
        }
    }
    
    var textFont: Font {
        switch self {
            case .assistant:
                    Theme.chat
            case .user:
                    Theme.chat
        }
    }
}

struct ChatBubble: View {
    @State var text: String
    let variant: ChatBubbleVariants
    @State private var currentBounds: Anchor<CGRect>? = nil
    @State private var isPressed: Bool = false
    @State private var entities: [wordEntity]?
    let onLongPress: ((_ elem: ChatElement) -> Void)?
    let id: UUID
    let elemType: ChatElementType?
    @State private var questionId: Int64?
    
    init(id: UUID? = nil, questionId: Int64? = nil, text: String, elemType: ChatElementType? = nil, variant: ChatBubbleVariants, entities: [wordEntity]? = nil, onLongPress: ((_ elem: ChatElement) -> Void)? = nil) {
        self._text = State(initialValue: text)
        self.variant = variant
        self.entities = entities
        self.onLongPress = onLongPress
        self.questionId = questionId
        self.elemType = elemType
        if let id = id {
            self.id = id
        } else {
            self.id = UUID()
        }
    }
    
    var body: some View {
        HStack{
            if text.isEmpty {
                MessageActivityIndicator()
                    .padding()
            } else {
                if self.variant == .user {
                    Spacer()
                }
                textView()
                    .font(variant.textFont)
                    .foregroundStyle(variant.textColor)
                    .padding(5)
                    .padding(.horizontal, 15)
                    .background{
                        ChatBubbleBg(direction: variant.direction)
                            .fill(variant.fillColor)
                            .scaleEffect(isPressed ? CGSize(width: 1.03, height: 1.03) : CGSize(width: 1, height: 1))
                            .animation(.bouncy, value: isPressed)
                    }
                    .anchorPreference(key: ChatBubbleSizePreferences.self, value: .bounds, transform: {[self.id: $0]})
                if self.variant == .assistant {
                    Spacer()
                }
            }
        }
        .onTapGesture {}
        .onLongPressGesture(perform: {
            if let onLongPress = self.onLongPress {
                onLongPress(ChatElement(id: id, type: elemType ?? .assistantMessage, text: text, entities: entities, questionId: questionId))
            }
        }, onPressingChanged: {
            isPressed = $0
        })
        .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds, transform: { $0
        })
        .onPreferenceChange(BoundsPreferenceKey.self, perform: { value in
            currentBounds = value
        })
        .onReceive(ContextualActionModel.shared.MessageEventsPublisher, perform: handleMessageEvent)
    }
    
    @ViewBuilder
    func textView() -> some View {
        if let entities = self.entities {
            TextWithEntities(text: text, entities: entities, questionId: questionId)
        } else {
            Text(.init(text))
        }
    }
    
    @MainActor
    func handleMessageEvent(_ event: MessageEvent) {
        guard event.messageId == self.id else {
            return
        }
        
        self.text = event.text
        self.questionId = event.questionId
        self.entities = event.entities
    }
}

enum bubbleDirection {
    case left, right
}

struct ChatBubbleBg: Shape {
    let direction: bubbleDirection
    
    func path(in rect: CGRect) -> Path {
        let path = Path(roundedRect: rect.insetBy(dx: 10, dy: 0), cornerRadius: 20)
        let indicator = {
            switch self.direction {
                case .left:
                    return leftSpeechIndicator(rect: rect)
                case .right:
                    return rightSpeechIndicator(rect: rect)
            }
        }()
        return path.union(indicator)
    }
    
    func leftSpeechIndicator (rect: CGRect) -> Path{
        var path = Path()
        let width = Double(30)
        let height = Double(30)
        let yPosition = rect.height - height
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addCurve(to: CGPoint(x: width, y: yPosition), control1: CGPoint(x: 0.16*width, y: yPosition + 0.91*height), control2: CGPoint(x: 0.58*width, y: yPosition + 0.58*height))
        path.addLine(to: CGPoint(x: width, y: yPosition + 0.67*height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
    
    func rightSpeechIndicator(rect: CGRect) -> Path {
        var path = Path()
        let width = Double(30)
        let height = Double(30)
        let yPosition = rect.height - height
        let xPosition = rect.width - width
        
        path.move(to: CGPoint(x: rect.width, y: rect.height))
        path.addCurve(to: CGPoint(x: xPosition, y: yPosition), control1: CGPoint(x: xPosition + 0.84*width, y: yPosition + 0.91*height), control2: CGPoint(x: xPosition + 0.42*width, y: yPosition + 0.58*height))
        path.addLine(to: CGPoint(x: xPosition, y: yPosition + 0.67*height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview{
    VStack{
        ChatBubble(text: "The quick brown fox jumped over the lazy dog", variant: .assistant, onLongPress: { _ in
        })
        ChatBubble(text: "The quick brown fox jumped over the lazy dog", variant: .user)
    }
}

struct ChatBubbleSizePreferences: PreferenceKey {
    typealias Value = [UUID: Anchor<CGRect>]

    static var defaultValue: Value { [:] }

    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value.merge(nextValue()) { $1 }
    }
}
