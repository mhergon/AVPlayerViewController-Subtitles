//
//  Subtitles.swift
//  Subtitles
//
//  Created by mhergon on 23/12/15.
//  Copyright © 2015 mhergon. All rights reserved.
//

import AVKit

enum SubtitleType {
    case srt
    case ass
    case ssa
    case unknown
}

public class Subtitles {

    // MARK: - Private properties
    
    private var parsedPayload: NSDictionary?
    
    // MARK: - Public methods
    
    public init(file filePath: URL, type: SubtitleType = .srt, encoding: String.Encoding = .utf8) throws {
        do {
            let str = try String(contentsOf: filePath, encoding: encoding)
            switch type {
            case .srt:
                parsedPayload = try Subtitles.parseSRT(str)
            case .ssa, .ass:
                parsedPayload = try Subtitles.parseSSA(str)
            case .unknown:
                parsedPayload = nil
            }
        } catch {
            do {
                let str = try String(contentsOf: filePath, encoding: .gb2312)
                switch type {
                case .srt:
                    parsedPayload = try Subtitles.parseSRT(str)
                case .ssa, .ass:
                    parsedPayload = try Subtitles.parseSSA(str)
                case .unknown:
                    parsedPayload = nil
                }
            } catch {
                parsedPayload = nil
            }
        }
    }
    
    public init(subtitles string: String) throws {
        // Parse string
        parsedPayload = try Subtitles.parseSubRip(string)
    }
    
    /// Search subtitles at time
    ///
    /// - Parameter time: Time
    /// - Returns: String if exists
    public func searchSubtitles(at time: TimeInterval) -> String? {
        return Subtitles.searchSubtitles(parsedPayload, time)
    }
    
}

extension Subtitles {
    
    static func parseSSA(_ payload: String) throws -> NSDictionary? {
        var payload = payload.replacingOccurrences(of: "\n\r\n", with: "\n\n")
        payload = payload.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        payload = payload.replacingOccurrences(of: "\r\n", with: "\n")
        
        let parsed = NSMutableDictionary()
        let formatRegex = try! NSRegularExpression(pattern: "\\[Events\\]\\nFormat:.+", options: .caseInsensitive)
        let formatMatches = formatRegex.matches(in: payload,
                                              options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                              range: NSMakeRange(0, payload.count))
        let formatLine = (payload as NSString).substring(with: formatMatches.first!.range)
        let commaCount = formatLine.components(separatedBy: ",").count - 1

        let lineRegex = try! NSRegularExpression(pattern: ".+(\\d+:\\d+:\\d+\\.\\d+,).+", options: .caseInsensitive)
        let allMatches = lineRegex.matches(in: payload,
                                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                    range: NSMakeRange(0, payload.count))
        var index = 0
        for linematch in allMatches {
            index += 1
            let eachline = (payload as NSString).substring(with: linematch.range)
            let timeRegex = try! NSRegularExpression(pattern: "\\d+:\\d+:\\d+\\.\\d+", options: .caseInsensitive)
            let timeMatches = timeRegex.matches(in: eachline,
                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                range: NSMakeRange(0, eachline.count))
            let fromString = (eachline as NSString).substring(with: timeMatches.first!.range)
            let toString = (eachline as NSString).substring(with: timeMatches[1].range)
            print("from:"+fromString)
            print("to:"+toString)
            let nontextRegex = try! NSRegularExpression(pattern: "(.*?,){\(commaCount)}", options: .caseInsensitive)
            let nontextMatches = nontextRegex.matches(in: eachline, range: NSMakeRange(0, eachline.count))
            let nontextRange = nontextMatches.first!.range
            let nontextLocation = nontextRange.location
            let nontextLength = nontextRange.length
            let textIndex = String.Index(utf16Offset: nontextLength+nontextLocation, in: eachline)
            let textString = eachline[textIndex...]
            let resultText = String(textString)
                .removeCurlyBracketsStrings()
                .replacingOccurrences(of: #"\N"#, with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print(resultText)
            
            var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
            
            var scanner = Scanner(string: fromString)
            h = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            m = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            s = scanner.scanDouble() ?? 0
            _ = scanner.scanString(",")
            c = scanner.scanDouble() ?? 0
            
            let fromTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
            
            scanner = Scanner(string: toString)
            h = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            m = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            s = scanner.scanDouble() ?? 0
            _ = scanner.scanString(",")
            c = scanner.scanDouble() ?? 0
            let toTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
            let final = NSMutableDictionary()
            final["from"] = fromTime
            final["to"] = toTime
            final["text"] = resultText
            parsed[index] = final
        }
        return parsed
    }
    static func parseSRT(_ payload: String) throws -> NSDictionary? {
        // Prepare payload
        var payload = payload.replacingOccurrences(of: "\n\r\n", with: "\n\n")
        payload = payload.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        payload = payload.replacingOccurrences(of: "\r\n", with: "\n")
        
        // Parsed dict
        let parsed = NSMutableDictionary()
        
        // Get groups
        let regexStr = "(\\d+)\\n([\\d:,.]+)\\s+-{2}\\>\\s+([\\d:,.]+)\\n([\\s\\S]*?(?=\\n{2,}|$))"
        let regex = try NSRegularExpression(pattern: regexStr, options: .caseInsensitive)
        let matches = regex.matches(in: payload, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, payload.count))
        for m in matches {
            let group = (payload as NSString).substring(with: m.range)
            
            // Get index
            var regex = try NSRegularExpression(pattern: "^[0-9]+", options: .caseInsensitive)
            var match = regex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.count))
            
            guard let i = match.first else {
                continue
            }
            
            let index = (group as NSString).substring(with: i.range)
            
            // Get "from" & "to" time
            regex = try NSRegularExpression(pattern: "\\d{1,2}:\\d{1,2}:\\d{1,2}[,.]\\d{1,3}", options: .caseInsensitive)
            match = regex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.count))
            
            guard match.count == 2 else {
                continue
            }
            
            guard let from = match.first, let to = match.last else {
                continue
            }
            
            var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
            
            let fromStr = (group as NSString).substring(with: from.range)
            var scanner = Scanner(string: fromStr)
            h = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            m = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            s = scanner.scanDouble() ?? 0
            _ = scanner.scanString(",")
            c = scanner.scanDouble() ?? 0
            
            let fromTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
            
            let toStr = (group as NSString).substring(with: to.range)
            scanner = Scanner(string: toStr)
            h = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            m = scanner.scanDouble() ?? 0
            _ = scanner.scanString(":")
            s = scanner.scanDouble() ?? 0
            _ = scanner.scanString(",")
            c = scanner.scanDouble() ?? 0
            let toTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
            
            // Get text & check if empty
            let range = NSMakeRange(0, to.range.location + to.range.length + 1)
            guard (group as NSString).length - range.length > 0 else {
                continue
            }
            
            let text = (group as NSString).replacingCharacters(in: range, with: "")
            
            // Create final object
            let final = NSMutableDictionary()
            final["from"] = fromTime
            final["to"] = toTime
            final["text"] = text
            parsed[index] = final
        }
        
        return parsed
    }
    
    /// Search subtitle on time
    ///
    /// - Parameters:
    ///   - payload: Inout payload
    ///   - time: Time
    /// - Returns: String
    static func searchSubtitles(_ payload: NSDictionary?, _ time: TimeInterval) -> String? {
        let predicate = NSPredicate(format: "(%f >= %K) AND (%f <= %K)", time, "from", time, "to")
        
        guard let values = payload?.allValues, let result = (values as NSArray).filtered(using: predicate).first as? NSDictionary else {
            return nil
        }
        
        guard let text = result.value(forKey: "text") as? String else {
            return nil
        }
        
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
}

extension String.Encoding {
    static let gb2312 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}
