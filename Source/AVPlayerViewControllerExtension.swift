//
//  AVPlayerViewControllerExtension.swift
//  AVPlayerViewController-Subtitles
//
//  Created by Crt Gregoric on 11/02/2022.
//  Copyright © 2022 Marc Hervera. All rights reserved.
//

import AVKit

#if os(iOS)
public extension AVPlayerViewController {
    
    private struct AssociatedKeys {
        static var FontKey = "FontKey"
        static var ColorKey = "FontKey"
        static var SubtitleKey = "SubtitleKey"
        static var SubtitleHeightKey = "SubtitleHeightKey"
        static var PayloadKey = "PayloadKey"
    }
    
    // MARK: - Public properties
    
    var subtitleLabel: UILabel? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.SubtitleKey) as? UILabel }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.SubtitleKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Private properties
    
    fileprivate var subtitleLabelHeightConstraint: NSLayoutConstraint? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.SubtitleHeightKey) as? NSLayoutConstraint }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.SubtitleHeightKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    fileprivate var parsedPayload: NSDictionary? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.PayloadKey) as? NSDictionary }
        set (value) { objc_setAssociatedObject(self, &AssociatedKeys.PayloadKey, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Public methods
    
    func addSubtitles() {
        // Create label
        addSubtitleLabel()
    }
    
    func open(fileFromLocal filePath: URL, encoding: String.Encoding = .utf8) throws {
        let contents = try String(contentsOf: filePath, encoding: encoding)
        show(subtitles: contents)
    }
    
    func open(fileFromRemote filePath: URL, encoding: String.Encoding = .utf8) {
        subtitleLabel?.text = "..."
        let dataTask = URLSession.shared.dataTask(with: filePath) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                //Check status code
                if statusCode != 200 {
                    NSLog("Subtitle Error: \(httpResponse.statusCode) - \(error?.localizedDescription ?? "")")
                    return
                }
            }
            
            // Update UI elements on main thread
            DispatchQueue.main.async {
                self.subtitleLabel?.text = ""
                if let checkData = data as Data?, let contents = String(data: checkData, encoding: encoding) {
                    self.show(subtitles: contents)
                }
            }
        }
        dataTask.resume()
    }
    
    func show(subtitles string: String) {
        // Parse
        parsedPayload = try? Subtitles.parseSubRip(string)
        if let parsedPayload = parsedPayload {
            addPeriodicNotification(parsedPayload: parsedPayload)
        }
    }
    
    func showByDictionary(dictionaryContent: NSMutableDictionary) {
        // Add Dictionary content direct to Payload
        parsedPayload = dictionaryContent
        if let parsedPayload = parsedPayload {
            addPeriodicNotification(parsedPayload: parsedPayload)
        }
    }
    
    func addPeriodicNotification(parsedPayload: NSDictionary) {
        // Add periodic notifications
        let interval = CMTimeMake(value: 1, timescale: 60)
        self.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let strongSelf = self, let label = strongSelf.subtitleLabel else {
                return
            }
            
            // Search && show subtitles
            label.text = Subtitles.searchSubtitles(strongSelf.parsedPayload, time.seconds)
            
            // Adjust size
            let baseSize = CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)
            let rect = label.sizeThatFits(baseSize)
            if label.text != nil {
                strongSelf.subtitleLabelHeightConstraint?.constant = rect.height + 5.0
            } else {
                strongSelf.subtitleLabelHeightConstraint?.constant = rect.height
            }
        }
    }
    
    fileprivate func addSubtitleLabel() {
        guard subtitleLabel == nil else {
            return
        }
        
        // Label
        subtitleLabel = UILabel()
        subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.backgroundColor = UIColor.clear
        subtitleLabel?.textAlignment = .center
        subtitleLabel?.numberOfLines = 0
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? 40.0 : 22.0
        subtitleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
        subtitleLabel?.textColor = .white
        subtitleLabel?.layer.shadowColor = UIColor.black.cgColor
        subtitleLabel?.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        subtitleLabel?.layer.shadowOpacity = 0.9
        subtitleLabel?.layer.shadowRadius = 1.0
        subtitleLabel?.layer.shouldRasterize = true
        subtitleLabel?.layer.rasterizationScale = UIScreen.main.scale
        subtitleLabel?.lineBreakMode = .byWordWrapping
        
        contentOverlayView?.addSubview(subtitleLabel!)
        
        // Position
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(20)-[l]-(20)-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["l" : subtitleLabel!])
        contentOverlayView?.addConstraints(constraints)
        constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[l]-(30)-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["l" : subtitleLabel!])
        contentOverlayView?.addConstraints(constraints)
        subtitleLabelHeightConstraint = NSLayoutConstraint(item: subtitleLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 30.0)
        contentOverlayView?.addConstraint(subtitleLabelHeightConstraint!)
    }
    
}
#endif
