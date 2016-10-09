//
//  Subtitles.swift
//  Subtitles
//
//  Created by mhergon on 23/12/15.
//  Copyright © 2015 mhergon. All rights reserved.
//

import ObjectiveC
import MediaPlayer
import AVKit
import CoreMedia

private struct AssociatedKeys {
    static var FontKey = "FontKey"
    static var ColorKey = "FontKey"
    static var SubtitleKey = "SubtitleKey"
    static var SubtitleHeightKey = "SubtitleHeightKey"
    static var PayloadKey = "PayloadKey"
}

public extension AVPlayerViewController {
    
    // MARK: - Public properties
    var subtitleLabel: UILabel? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.SubtitleKey) as? UILabel }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.SubtitleKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Private properties
    private var subtitleLabelHeightConstraint: NSLayoutConstraint? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.SubtitleHeightKey) as? NSLayoutConstraint }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.SubtitleHeightKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var parsedPayload: NSDictionary? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.PayloadKey) as? NSDictionary }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.PayloadKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Public methods
    func addSubtitles() -> Self {
        
        // Create label
        addSubtitleLabel()
        
        return self
        
    }
    
    func open(file filePath: URL, encoding: String.Encoding = String.Encoding.utf8) {
        
        do {
            let contents = try String(contentsOf: filePath, encoding: encoding)
//            print("contents: \(contents)")
            
            show(subtitles: contents)
            
        } catch let error as NSError {
            print("Failed reading from URL: \(filePath), Error: " + error.localizedDescription)
        }
        
    }
    
    func show(subtitles string: String) {
        
        // Parse
        parsedPayload = parseSubRip(payload: string)
        
        // Add periodic notifications
        self.player?.addPeriodicTimeObserver(
            forInterval: CMTimeMake(1, 60),
            queue: DispatchQueue.main,
            using: { (time) -> Void in
                
                // Search && show subtitles
                self.searchSubtitles(time: time)
        })
        
    }
    
    // MARK: - Private methods
    private func addSubtitleLabel() {
        
        guard let _ = subtitleLabel else {
            
            // Label
            subtitleLabel = UILabel()
// MARK: - Private methods
    private func addSubtitleLabel() {
        
        guard let _ = subtitleLabel else {
            
            // Label
            subtitleLabel = UILabel()
            subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel?.backgroundColor = UIColor.clear
            subtitleLabel?.textAlignment = .center
            subtitleLabel?.numberOfLines = 0
            subtitleLabel?.font = UIFont.systemFont(ofSize: UI_USER_INTERFACE_IDIOM() == .pad ? 40.0 : 22.0)
            subtitleLabel?.textColor = UIColor.white
            subtitleLabel?.numberOfLines = 0;
            subtitleLabel?.layer.shadowColor = UIColor.black.cgColor
            subtitleLabel?.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
            subtitleLabel?.layer.shadowOpacity = 0.9;
            subtitleLabel?.layer.shadowRadius = 1.0;
            subtitleLabel?.layer.shouldRasterize = true;
            subtitleLabel?.layer.rasterizationScale = UIScreen.main.scale
            
            //            let subtitleWidth = self.bounds.width;
            //            let subtitleHeight = self.bounds.height;
            //
            //            let subtitleOrigin = CGPoint(x: 0, y: 0)
            
            //            let viewSize = CGSize(width: subtitleWidth, height: subtitleHeight)
            //            let viewFrame = CGRect(origin: subtitleOrigin, size: viewSize)
            let contentOverlayView = UIView()
            
            contentOverlayView.addSubview(subtitleLabel!)
            //            contentOverlayView.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
            addSubview(contentOverlayView)
            
            //Position
            constrain(contentOverlayView) {view1 in
                view1.width == view1.superview!.width
                view1.height == view1.superview!.height * 0.25
                view1.bottom == view1.superview!.bottom
                view1.leading == view1.superview!.leading
                view1.trailing == view1.superview!.trailing
                view1.centerY == view1.superview!.centerY
            }
            
            constrain(subtitleLabel!) {view1 in
                view1.width == view1.superview!.width
                view1.height == view1.superview!.height
                view1.leading == view1.superview!.leading + 5
                view1.trailing == view1.superview!.trailing - 5
                view1.centerX == view1.superview!.centerX
                view1.centerY == view1.superview!.centerY
            }
            
            return
        }
        
    }
    
    private func parseSubRip(payload: String) -> NSDictionary? {
        
        do {
            
            // Prepare payload
            var payload = payload.stringByReplacingOccurrencesOfString("\n\r\n", withString: "\n\n")
            payload = payload.stringByReplacingOccurrencesOfString("\n\n\n", withString: "\n\n")
            
            // Parsed dict
            let parsed = NSMutableDictionary()
            
            // Get groups
            let regexStr = "(?m)(^[0-9]+)([\\s\\S]*?)(?=\n\n)"
            let regex = try NSRegularExpression(pattern: regexStr, options: .CaseInsensitive)
            let matches = regex.matchesInString(payload, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, payload.characters.count))
            for m in matches {
                
                let group = (payload as NSString).substringWithRange(m.range)
                
                // Get index
                var regex = try NSRegularExpression(pattern: "^[0-9]+", options: .CaseInsensitive)
                var match = regex.matchesInString(group, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, group.characters.count))
                guard let i = match.first else {
                    continue
                }
                let index = (group as NSString).substringWithRange(i.range)
                
                // Get "from" & "to" time
                regex = try NSRegularExpression(pattern: "\\d{1,2}:\\d{1,2}:\\d{1,2},\\d{1,3}", options: .CaseInsensitive)
                match = regex.matchesInString(group, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, group.characters.count))
                guard match.count == 2 else {
                    continue
                }
                guard let from = match.first, let to = match.last else {
                    continue
                }
                
                var h: NSTimeInterval = 0.0, m: NSTimeInterval = 0.0, s: NSTimeInterval = 0.0, c: NSTimeInterval = 0.0
                
                let fromStr = (group as NSString).substringWithRange(from.range)
                var scanner = NSScanner(string: fromStr)
                scanner.scanDouble(&h)
                scanner.scanString(":", intoString: nil)
                scanner.scanDouble(&m)
                scanner.scanString(":", intoString: nil)
                scanner.scanDouble(&s)
                scanner.scanString(",", intoString: nil)
                scanner.scanDouble(&c)
                let fromTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
                
private func parseSubRip(payload: String) -> NSDictionary? {
        
        do {
            
            var payload = payload
            
            // Prepare payload
//            print("payload: \(payload)", terminator: "")
            payload = payload.replacingOccurrences(of: "\n\r\n", with: "\n\n")
            payload = payload.replacingOccurrences(of: "\n\n\n", with: "\n\n")


            // Parsed dict
            let parsed = NSMutableDictionary()
            
            
            // Get groups
            let regexStr = "(?m)(^[0-9]+)([\\s\\S]*?)(?=\n\n)"
            let regex = try NSRegularExpression(pattern: regexStr, options: .caseInsensitive)
            
            

            let lastIndexInt = (payload as NSString).length
            
            let range = NSRange(location: 0, length: lastIndexInt)
            let options = NSRegularExpression.MatchingOptions(rawValue: 0)
            
            
            let matches = regex.matches(in: payload, options: options, range: range)
            
            print("matches.count: \(matches.count)")
            
            for m in matches {
                
                let group = (payload as NSString).substring(with: m.range)
                
                
                
                // Get index
                var regex = try NSRegularExpression(pattern: "^[0-9]+", options: .caseInsensitive)
                var match = regex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.characters.count))
                
                guard let i = match.first else {
                    continue
                }
                
                
                let index = (group as NSString).substring(with: i.range)
                //                print("index: \(index)")
                
                // Get "from" & "to" time
                
                
                regex = try NSRegularExpression(pattern: "\\d{1,2}:\\d{1,2}:\\d{1,2},\\d{1,3}", options: .caseInsensitive)
                match = regex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.characters.count))
                guard match.count == 2 else {
                    continue
                }
                guard let from = match.first, let to = match.last else {
                    continue
                }
                
                var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
                
                let fromStr = (group as NSString).substring(with: from.range)
                var scanner = Scanner(string: fromStr)
                scanner.scanDouble(&h)
                scanner.scanString(":", into: nil)
                scanner.scanDouble(&m)
                scanner.scanString(":", into: nil)
                scanner.scanDouble(&s)
                scanner.scanString(",", into: nil)
                scanner.scanDouble(&c)
                let fromTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
                
                let toStr = (group as NSString).substring(with: to.range)
                scanner = Scanner(string: toStr)
                scanner.scanDouble(&h)
                scanner.scanString(":", into: nil)
                scanner.scanDouble(&m)
                scanner.scanString(":", into: nil)
                scanner.scanDouble(&s)
                scanner.scanString(",", into: nil)
                scanner.scanDouble(&c)
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
            
        } catch let error as NSError {
            print("error: \(error)")
            return nil
            
        }
        
    }

    
    private func searchSubtitles(time: CMTime) {
        
        let predicate = NSPredicate(format: "(%f >= %K) AND (%f <= %K)", time.seconds, "from", time.seconds, "to")
        
        guard let values = parsedPayload?.allValues else {
            
            return
        }
        guard let result = (values as NSArray).filtered(using: predicate).first as? NSDictionary else {
            subtitleLabel?.text = ""
            return
        }
        
        
        
        guard let label = subtitleLabel else {
            return
        }
        
        // Set text
        label.text = (result["text"] as! String).trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        
        // Adjust size
        let rect = (label.text! as NSString)
            .boundingRect(with: CGSize(width: label.bounds.width, height: CGFloat.greatestFiniteMagnitude),
                          options: .usesLineFragmentOrigin,
                          attributes: [NSFontAttributeName : label.font!], context: nil)
        subtitleLabelHeightConstraint?.constant = rect.size.height + 5.0
    }
    
}
