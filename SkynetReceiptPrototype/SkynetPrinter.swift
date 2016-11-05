//
//  SkynetPrinter.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 10/14/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation


class SkynetPrinter: PrinterManager {
    
    
    
    let retailer: RetailerObject
    let writer: ZPLHelper

    init(delegate: PrinterManagerDelegate, labelWidth: Int, labelLength: Int, retailer: RetailerObject) {
        self.retailer = retailer
        self.writer = ZPLHelper(labelWidth: labelWidth, labelLength: labelLength)
        super.init(delegate: delegate)
    }
    
    func printInvoice() {
        
        
        
    }
    
}
