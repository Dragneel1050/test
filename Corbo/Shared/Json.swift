//

import Foundation

class ApiDateFormatter: DateFormatter {
    
    static var calendar = Calendar(identifier: .gregorian)
    
    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    static var timestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return df
    }()
    
    static var fractionalTimestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSZ"
        return df
    }()
    
    override func date(from string: String) -> Date? {
        var result: Date?
        if let date = ApiDateFormatter.dateFormatter.date(from: string) {
            result = date
        } else if let timestamp = ApiDateFormatter.timestampFormatter.date(from: string) {
            result = timestamp
        } else if let fractional = ApiDateFormatter.fractionalTimestampFormatter.date(from: string) {
            result = fractional
        }
        
        return result
    }
    
    override func string(from date: Date) -> String {
        var result: String
        
        let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
        if dateComponents.hour == 0 && dateComponents.minute == 0 && dateComponents.second == 0 {
            result = ApiDateFormatter.dateFormatter.string(from: date)
        } else {
            result = ApiDateFormatter.timestampFormatter.string(from: date)
        }
        
        return result
    }
}


extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(ApiDateFormatter())
        return decoder
    }()
}

extension JSONEncoder {
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(ApiDateFormatter())
        return encoder
    }()
}

