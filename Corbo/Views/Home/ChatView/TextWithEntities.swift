//
//  TextWithEntities.swift
//  Corbo
//
//  Created by Agustín Nanni on 04/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct TextWithEntities: View {
    let text: String
    let entities: [wordEntity]
    let storyId: Int64?
    let questionId: Int64?

    private let controlSequence = "YWd1cw=="
    private let implementedEntities: Set<wordEntityType> = [.person]
    
    init(text: String, entities: [wordEntity], storyId: Int64? = nil, questionId: Int64? = nil) {
        self.text = text
        self.entities = entities
        self.storyId = storyId
        self.questionId = questionId
    }
    
    var body: some View {
        buildView(text: text, entities: entities)
        .environment(\.openURL, OpenURLAction { url in
            guard let host = url.host() else {
                AppLogs.defaultLogger.warning("TextWithEntities: missing host \(url)")
                return .discarded
            }
            
            guard let data = Data(base64Encoded: host) else {
                AppLogs.defaultLogger.warning("TextWithEntities: invalid data \(host)")
                
                let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                if !matches.isEmpty {
                    if let range = Range(matches[0].range, in: text) {
                        var str = String(text[range])
                        if !(str.hasPrefix("https://") || str.hasPrefix("http://")) {
                            str = "https://" + str
                        }
                        
                        if let url = URL(string: str) {
                            return .systemAction(url)
                        }
                    }
                }

                return .discarded
            }
            
            guard let context = try? JSONDecoder().decode(entityBindingData.self, from: data) else {
                AppLogs.defaultLogger.warning("TextWithEntities: unable to parse data \(host)")
                return .discarded
            }
            
            guard let entity = entities.first(where: { $0.name == context.name}) else {
                AppLogs.defaultLogger.warning("TextWithEntities: missing entity")
                return .discarded
            }
            
            
            
            if let externalId = findExternalId(entity) {
                Task{
                    guard let contact = await ContactsModel.shared.findContactById(externalId) else {
                        AppLogs.defaultLogger.warning("TextWithEntities: cant find contact \(externalId)")
                        
                        return
                    }
                    HomeModel.shared.chatViewOpen = false
                    HomeModel.shared.homeNavPath.append(contact)
                    EventsModel.shared.track(ViewNerContactDetails())
                }
            } else {
                let fullContext = entityBindingContext(entity: entity, storyId: context.storyId, questionId: context.questionId)
                
                NavigationModel.shared.triggerEntityBinding(fullContext)
                StoriesModel.shared.prepareStoriesView()
                EventsModel.shared.track(ViewNerBindingTray())
            }
        
            return .handled
        })
    }
    
    fileprivate func findExternalId(_ entity: wordEntity) -> Int64? {
        if let externalId = entity.externalId {
            return externalId
        }
        
        return nil
    }
    
    fileprivate func buildTextWithEntities(text: String, entities: [wordEntity]) -> [textWithEntities] {
        var result = [textWithEntities]()
        let textToUse = {
            if text.last == "." {
                return text
            } else {
                return text + "."
            }
        }()
                
        result.append(textWithEntities(text: textToUse, attribute: nil))

        for entity in entities {
            if entity.name != nil && entity.type != nil && implementedEntities.contains(entity.type!) {
                result = populateArrayWithEntity(result, entity: entity)
            }
        }
                
        return result
    }
    
    fileprivate func populateArrayWithEntity(_ array: [textWithEntities], entity: wordEntity) -> [textWithEntities] {
        var newArray = [textWithEntities]()

        for textPart in array {
            if textPart.attribute == nil {
                var textToUse = textPart.text
                if textToUse.hasPrefix(entity.name!) {
                    textToUse = controlSequence + textToUse
                }
                let contentParts = textToUse.split(separator: entity.name!)
                for (idx, part) in contentParts.enumerated() {
                    newArray.append(textWithEntities(text: String(part), attribute: nil))
                    
                    if idx != contentParts.count - 1 {
                        newArray.append(textWithEntities(text: String(entity.name!), attribute: entity))
                    }
                    
                    
                }
            } else {
                newArray.append(textPart)
            }
        }
        
        return newArray
    }

    fileprivate func buildView(text: String, entities: [wordEntity]) -> some View {
        let textWithEntities = buildTextWithEntities(text: text, entities: entities)
        
        var view = Text("")
        
        for part in textWithEntities {
            var text: String
            
            if part.text == controlSequence {
                continue
            }
            
            if let attr = part.attribute {
                let data = entityBindingData(entityId: attr.externalId ?? -1, name: attr.name ?? "", storyId: storyId, questionId: questionId)
                
                let json = try! JSONEncoder().encode(data)
                
                text = "[_\(part.text)_](\(attr.type!.rawValue)://\(json.base64EncodedString()))"
                view = view + Text(.init(text))
                    .underline()
                
            } else {
                text = part.text
                view = view + Text(.init(text))
            }
        }
        
        return view
            .foregroundStyle(.textPrimary)
            .tint(.textEntity)
    }
}

fileprivate struct entityBindingData: Codable {
    let entityId: Int64
    let name: String
    let storyId: Int64?
    let questionId: Int64?
    
    init(entityId: Int64, name: String, storyId: Int64?, questionId: Int64?) {
        self.entityId = entityId
        self.name = name
        self.storyId = storyId
        self.questionId = questionId
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entityId = try container.decode(Int64.self, forKey: .entityId)
        self.name = try container.decode(String.self, forKey: .name)
        self.storyId = try container.decodeIfPresent(Int64.self, forKey: .storyId)
        self.questionId = try container.decodeIfPresent(Int64.self, forKey: .questionId)
    }
}

fileprivate struct textWithEntities {
    let text: String
    let attribute: wordEntity?
}

#Preview {
    VStack{
        HStack{
            Spacer()
        }
        Spacer()
        TextWithEntities(text: "Agustin Nanni Hello my name is Agustin Nanni this is a Link", entities: [wordEntity(name: "Agustin Nanni", type: .person, externalId: 1234), wordEntity(name: "Link", type: .person, externalId: 1234)], storyId: 1, questionId: nil)
        Spacer()
    }
    .background{
        Background()
    }
}
