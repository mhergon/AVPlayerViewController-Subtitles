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
    
    func open(file filePath: NSURL, encoding: NSStringEncoding = NSUTF8StringEncoding) {
        
        let contents = try! String(contentsOfURL: filePath, encoding: encoding)
        show(subtitles: contents)
        
    }
    
    func show(subtitles string: String) {
        
        // Parse
        parsedPayload = parseSubRip(string)
        
        // Add periodic notifications
        self.player?.addPeriodicTimeObserverForInterval(
            CMTimeMake(1, 60),
            queue: dispatch_get_main_queue(),
            usingBlock: { (time) -> Void in
                
                // Search && show subtitles
                self.searchSubtitles(time)
                
        })
        
    }
    
    // MARK: - Private methods
    private func addSubtitleLabel() {
        
        guard let _ = subtitleLabel else {
            
            // Label
            subtitleLabel = UILabel()
            subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel?.backgroundColor = UIColor.clearColor()
            subtitleLabel?.textAlignment = .Center
            subtitleLabel?.numberOfLines = 0
            subtitleLabel?.font = UIFont.boldSystemFontOfSize(UI_USER_INTERFACE_IDIOM() == .Pad ? 40.0 : 22.0)
            subtitleLabel?.textColor = UIColor.whiteColor()
            subtitleLabel?.numberOfLines = 0;
            subtitleLabel?.layer.shadowColor = UIColor.blackColor().CGColor
            subtitleLabel?.layer.shadowOffset = CGSizeMake(1.0, 1.0);
            subtitleLabel?.layer.shadowOpacity = 0.9;
            subtitleLabel?.layer.shadowRadius = 1.0;
            subtitleLabel?.layer.shouldRasterize = true;
            subtitleLabel?.layer.rasterizationScale = UIScreen.mainScreen().scale
            subtitleLabel?.lineBreakMode = .ByWordWrapping
            contentOverlayView?.addSubview(subtitleLabel!)
            
            // Position
            var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(20)-[l]-(20)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["l" : subtitleLabel!])
            contentOverlayView?.addConstraints(constraints)
            constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[l]-(30)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["l" : subtitleLabel!])
            contentOverlayView?.addConstraints(constraints)
            subtitleLabelHeightConstraint = NSLayoutConstraint(item: subtitleLabel!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 30.0)
            contentOverlayView?.addConstraint(subtitleLabelHeightConstraint!)
            
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
            
            let lastIndexStr = String(payload.endIndex)
            let lastIndexInt = Int(lastIndexStr)
            
            let matches = regex.matchesInString(payload, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, lastIndexInt!))
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
                
                let toStr = (group as NSString).substringWithRange(to.range)
                scanner = NSScanner(string: toStr)
                scanner.scanDouble(&h)
                scanner.scanString(":", intoString: nil)
                scanner.scanDouble(&m)
                scanner.scanString(":", intoString: nil)
                scanner.scanDouble(&s)
                scanner.scanString(",", intoString: nil)
                scanner.scanDouble(&c)
                let toTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
                
                // Get text & check if empty
                let range = NSMakeRange(0, to.range.location + to.range.length + 1)
                guard (group as NSString).length - range.length > 0 else {
                    continue
                }
                let text = (group as NSString).stringByReplacingCharactersInRange(range, withString: "")
                
                // Create final object
                let final = NSMutableDictionary()
                final["from"] = fromTime
                final["to"] = toTime
                final["text"] = text
                parsed[index] = final
                
            }
            
            print(parsed)
            return parsed
            
        } catch {
            
            return nil
            
        }
        
    }
    
    private func searchSubtitles(time: CMTime) {
        
        let predicate = NSPredicate(format: "(%f >= %K) AND (%f <= %K)", time.seconds, "from", time.seconds, "to")
        
        guard let values = parsedPayload?.allValues else {
            return
        }
        guard let result = (values as NSArray).filteredArrayUsingPredicate(predicate).first as? NSDictionary else {
            subtitleLabel?.text = ""
            return
        }
        guard let label = subtitleLabel else {
            return
        }
        
        // Set text
        label.text = (result["text"] as! String).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        // Adjust size
        let rect = (label.text! as NSString).boundingRectWithSize(CGSize(width: CGRectGetWidth(label.bounds), height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName : label.font!], context: nil)
        subtitleLabelHeightConstraint?.constant = rect.size.height + 5.0
        
    }
    
}
