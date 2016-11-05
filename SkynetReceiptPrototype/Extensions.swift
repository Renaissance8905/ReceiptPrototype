//
//  Extensions.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 1/20/16.
//  Copyright © 2016 Chris Spradling. All rights reserved.
//

import Foundation
import MapKit


func sizeToIndex(_ size: Int) -> Int {
    switch size {
    case 15: return 0
    case 7: return 1
    case 6: return 2
    case 12: return 3
    default: return 4
    }
}


func indexToSize(_ idx: Int, defaultToHalf:Bool=false) -> Int {
    switch idx {
    case 0: return 15
    case 1: return 7
    case 2: return 6
    case 3: return 12
    default:
        if defaultToHalf {return 15}
        else {return 0}
    }
}




extension UIColor {
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}




extension UISplitViewController {
    func preferredBarButtonItem() -> UIBarButtonItem? {
        if self.displayMode == UISplitViewControllerDisplayMode.primaryHidden || self.displayMode == UISplitViewControllerDisplayMode.primaryOverlay {
            let btn =  UIBarButtonItem(image: UIImage(named:"menu_filled"),
                                                                   landscapeImagePhone: UIImage(named:"menu_filled"),
                                                                   style: UIBarButtonItemStyle.plain,
                                                                   target: self.displayModeButtonItem.target,
                                                                   action: self.displayModeButtonItem.action)
            btn.tintColor = UIColor.gray
            return btn
        }
        return nil
    }
    
    
    func isCollapsible() -> Bool {
        return self.displayMode == UISplitViewControllerDisplayMode.primaryHidden
            || self.displayMode == UISplitViewControllerDisplayMode.primaryOverlay
    }
}




extension Date {
    func isGreaterThanDate(_ dateToCompare: Date) -> Bool {
        return self.compare(dateToCompare) == ComparisonResult.orderedDescending
    }
    
    
    func isLessThanDate(_ dateToCompare: Date) -> Bool {
        return self.compare(dateToCompare) == ComparisonResult.orderedAscending
    }
    
    
    func equalToDate(_ dateToCompare: Date) -> Bool {
        return self.compare(dateToCompare) == ComparisonResult.orderedSame
    }
    
    
    func addDays(_ daysToAdd: Int) -> Date {
        let secondsInDays: TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        return self.addingTimeInterval(secondsInDays)
    }
    
    
    func addHours(_ hoursToAdd: Int) -> Date {
        let secondsInHours: TimeInterval = Double(hoursToAdd) * 60 * 60
        return self.addingTimeInterval(secondsInHours)
    }
    
    
    func isToday() -> Bool {
        let timeToFirstSunday: TimeInterval = 273600
        let week: TimeInterval = 604800
        let now = Date().timeIntervalSince1970
        let timeSinceMostRecentSunday: TimeInterval = (now - timeToFirstSunday).truncatingRemainder(dividingBy: week)
        return self.isGreaterThanDate(Date().addingTimeInterval(-timeSinceMostRecentSunday))
    }
}









extension UIViewController {
    
    
    func keyboardAdapt() {
        NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y = -keyboardSize.height
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
            self.view.frame.origin.y = 0
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

