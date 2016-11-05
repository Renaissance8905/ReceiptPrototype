//
//  ZPLHelper.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 10/13/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation



class ZPLHelper: NSObject {
    
    let width: Int
    let length: Int
    var commands: String = ""
    var cursorX: Int = 0
    var cursorY: Int = 0
    
    required init(labelWidth w: Int, labelLength l: Int) {
        self.width = w
        self.length = l
        self.commands.append("^XA^POI^PW\(w)^MNN^LL\(l)^LH0,0^CI28")

        super.init()
    }
    
    
    func reset() {
        self.commands = "^XA^POI^PW\(self.width)^MNN^LL\(self.length)^LH0,0^CI28"
    }
    
    
    func clear() {
        self.commands = ""
    }
    
    
    func moveCursorBy(x: Int, y: Int) {
        self.moveCursorTo(x: self.cursorX + x, y: self.cursorY + y)
    }
    
    
    func moveCursorTo(x: Int, y: Int) {
        self.cursorX = x
        self.cursorY = y
        self.commands.append("^FO\(x),\(y)")
    }
    
    
    func drawImage(withDataString: String, byteCount: Int, bytesPerRow: Int) {
        let b = byteCount
        let bpr = bytesPerRow
        let str = withDataString
        
        /*  command used:
             - ^GFa,b,c,d,data
             a = compression type
             b = binary byte count
             c = graphic field count
             d = bytes per row
             data = data
        */
        
        self.commands.append("^GFA,\(b),\(b),\(bpr),\(str)^FS")
    }
    
    
    func drawBox(thickness: Int, w: Int, h: Int) {
        self.commands.append("^GB\(w),\(h),\(thickness)^FS")
    }
    
    
    func drawHorizontalLine(thickness t: Int) {
        self.commands.append("^GB\(self.width),\(t),\(t)^FS")
    }
    
    
    func addWrappingText(text: String, fontHeight h: Int) {
        self.commands.append("^A0N,\(h),\(h)")
        self.commands.append("^FB\(self.width-20),10,,^FD\(text)^FS")
    }
    
    
    func addWrappingText(text: String, fontHeight h: Int, boxWidth w: Int, textLines nlines: Int) {
        self.commands.append("^A0,\(h),\(h)")
        self.commands.append("^FB\(w),\(nlines),,^FD\(text)^FS")
    }
    
    
    func addTextBox(text: String, boxWidth w: Int, fontHeight h: Int) {
        self.commands.append("^A0N,\(h),\(h)")
        self.commands.append("^TBN,\(w),\(h-1)")
        self.commands.append("^FD\(text)^FS")
    }
    
    
    func addText(text: String, fontHeight h: Int) {
        self.commands.append("^A0N,\(h),\(h)")
        self.commands.append("^FD\(text)^FS")
    }
    
    
    func addPDF417Barcode(withString s: String) {
        /* commands used:
             - ^BYw,r,h
             w = module width (in dots)
             r = wide bar to narrow bar width ratio (optional)
             h = bar code height (in dots)
             - ^B7o,h,s,c,r,t
             o = orientation
             h = bar code height for individual rows (in dots)
             s = security level
             c = number of data columns to encode
             r = number of rows to encode
             t = truncate right row indicators and stop pattern
        */
        
        // if barcode is not printed, it can be because the number of rows/columns is too small
        // @TODO(diego): add parameters of ^BY and ^B7 as method parameters
        self.commands.append("^BY3,3^B7N,5,5,7,20,N^FD\(s)^FS")
    }
    
    
    func addCustomCommand(command: String) {
        self.commands.append(command)
    }
    
    
    func finish() {
        self.commands.append("^XZ")
    }
    
    
    func getCommands() -> String {
        return self.commands
    }
}
