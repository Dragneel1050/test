//

import Foundation
import CoreML

class CNNModel {
    enum CNNModelErrors: Error {
        case dictionaryNotFound, unableToReadDict, invalidDictData, unableToVectorize
    }
    
    private var dictionary: [String: Int]? = nil
    private var model: CNN_Intent_Classifier_0_0_2? = nil
    private let MAX_SEQUENCE_LENGTH = 300
    
    func predict(_ text: String) throws -> CNNModelResult {
        if dictionary == nil {
            try readDictionary()
        }
        
        model = try CNN_Intent_Classifier_0_0_2()
                        
        let vector = try vectorizeText(text)
        
        let prediction = try self.model!.prediction(embedding_36_input: vector)
        
        return CNNModelResult(prediction)
    }
    
    private func initTensor() throws -> MLMultiArray {
        let tensor = try MLMultiArray(shape: [1, NSNumber(value: MAX_SEQUENCE_LENGTH)], dataType: .int32)
        
        for i in (0..<MAX_SEQUENCE_LENGTH) {
            let key = [0, i] as [NSNumber]
            tensor[key] = 0
        }
        
        return tensor
    }
    
    private func vectorizeText(_ text: String) throws -> MLMultiArray {
        let tensor = try initTensor()
        let comps = text.split(separator: " ")
        let regex = /[^\w\s\d]/
        
        for (idx, elem) in comps.enumerated() {
            var hasQuestionMark = false
            
            if idx == MAX_SEQUENCE_LENGTH {
                break
            }
            
            if elem.contains("?") {
                hasQuestionMark = true
            }
            
            let part = elem.lowercased().replacing(regex, with: "")
            if part.isEmpty || isStringNumeric(string: part) {
                continue
            }
            
            if let token = dictionary![String(part)] {
                tensor[[0, idx as NSNumber]] = NSNumber(integerLiteral: token)
                if hasQuestionMark {
                    let questionMark = dictionary!["?"]!
                    tensor[[0, idx + 1 as NSNumber]] = NSNumber(integerLiteral: questionMark)
                }
            } else{
                tensor[[0, idx as NSNumber]] = NSNumber(integerLiteral: 0)
            }
        }
                
        return tensor
    }
    
    func isStringNumeric(string: String) -> Bool {
        let digits = CharacterSet.decimalDigits
        let stringSet = CharacterSet(charactersIn: string)

        return digits.isSuperset(of: stringSet)
    }
                
    private func readDictionary() throws {
        guard let filepath = Bundle.main.path(forResource: "dictData", ofType: "json") else {
            throw CNNModelErrors.dictionaryNotFound
        }
        
        let data = try String(contentsOfFile: filepath)
        
        let dict = try JSONDecoder().decode([dictKey].self, from: data.data(using: .utf8)!)
        
        var result = [String: Int]()
    
        for value in dict {
            result[value.word] = value.key
        }
        
        self.dictionary = result
        
        AppLogs.defaultLogger.info("readDictionary: dictionary loaded! count: \(self.dictionary!.count)")
    }
    
    struct dictKey: Decodable {
        let key: Int
        let word: String
    }
}

struct CNNModelResult {
    let addStory: Double
    let askQuestion: Double
    let searchYourContacts: Double
    let unknown: Double
    let searchYourStories: Double
    
    let src: CNN_Intent_Classifier_0_0_2Output
    
    init(_ src: CNN_Intent_Classifier_0_0_2Output) {
        self.src = src
        
        self.addStory = src.Identity[0].doubleValue
        self.askQuestion = src.Identity[1].doubleValue
        self.searchYourContacts = src.Identity[2].doubleValue
        self.unknown = src.Identity[3].doubleValue
        self.searchYourStories = src.Identity[4].doubleValue
    }
    
    func strongest() -> CNNModelResultTypes {
        var max = Double(0)
        var maxIdx = 0
        let typesByIndex = [
            0: CNNModelResultTypes.addStory,
            1: CNNModelResultTypes.askQuestion,
            2: CNNModelResultTypes.searchYourContacts,
            3: CNNModelResultTypes.unknown,
            4: CNNModelResultTypes.searchYourStories
        ]
        
        for idx in (0..<src.Identity.count){
            let val = src.Identity[idx]
            if val.doubleValue > max {
                max = val.doubleValue
                maxIdx = idx
            }
        }
        
        return typesByIndex[maxIdx]!
    }
    
    func toString() -> String {
        let strongest = self.strongest()
        
        var result = "Strongest prediction: \(strongest.name) \n\n"
        result += "Add Story: \(self.addStory.description) \n"
        result += "Ask Question: \(self.askQuestion.description) \n"
        result += "Search your Contacts: \(self.searchYourContacts.description) \n"
        result += "Unknown: \(self.unknown.description) \n"
        result += "Search your Stories: \(self.searchYourStories.description) \n"
        
        return result
    }
    
    private func round(_ src: Double) -> String {
        return String(format: "%.2f", src)
    }
}

enum CNNModelResultTypes: String, Codable {
    case addStory, askQuestion, searchYourContacts, unknown, searchYourStories
    
    var name: String {
        switch self {
            case .addStory:
                "Add story"
            case .askQuestion:
                "Ask question"
            case .searchYourContacts:
                "Search your contacts"
            case .unknown:
                "Unknown"
            case .searchYourStories:
                "Search your stories"
        }
    }
    
    var value: String {
        switch self {
        case .addStory:
            "addStory"
        case .askQuestion:
            "askQuestion"
        case .searchYourContacts:
            "searchYourContacts"
        case .unknown:
            "unknown"
        case .searchYourStories:
            "searchYourStories"
        }
    }
}
