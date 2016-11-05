//
//  BrandObject.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 5/28/16.
//  Copyright © 2016 Chris Spradling. All rights reserved.
//

import Foundation
import UIKit

class OnSiteBrand {
    

    //State Controllers
    var todayLevel: Float?
    var todaySale: Int?
    var levelAttendedTo = false
    var saleAttendedTo = false
    var saleRecorded = false
    var complete = false
    
    
    //Incoming Values
    let displayName: String  // Full name of brand plus longhand size (Hefeweizen - Half Barrel)
    let brandShorthand: String // Includes HW, HW.25, HW.6, HW.12
    let brandID: String // Brand abbreviation with no sizing suffix
    let sizeClass: Int
    var loadoutQty: Int = 0
    
    let controllingRetailer: RetailerObject
    var parentTruck: RouteObject {return controllingRetailer.parentTruck}
    var retailerIDString: String {return String(self.controllingRetailer.id)}
    var retailerID: Int {return self.controllingRetailer.id}
    var price: Double {return self.inventoryReference.Price}
    var inventoryReference: PackageSize

    
    init(data: Dictionary<String, AnyObject>, retailer: RetailerObject) {
        
        self.controllingRetailer = retailer
        let inventoryController = retailer.parentTruck.Inventory
                
        self.brandID = data["brand"] as? String ?? "HW"
        self.sizeClass = (data["size"] as? NSString)?.integerValue ?? 15
        self.loadoutQty = (data["quantity"] as? NSString)?.integerValue ?? 0
        self.inventoryReference = inventoryController[brandID]![sizeClass]!

        self.displayName = inventoryReference.description
        self.brandShorthand = inventoryReference.shorthand
        
        
        
        // Further init protocols
    }
    // Further Brand Functionality
    
    
    var brandShorthandWithLoadout: String {
        return String(self.loadoutQty) + "x" + self.brandShorthand
    }
    
    
    var brandShorthandWithSaleAmt: String {
        return String(self.todaySale ?? 0) + "x" + self.brandShorthand
    }
    
    
    
    func resetSale() {
        self.parentTruck.deleteSale(self)
        self.complete = false
    }
    
    var isSellable: Bool {
        return true
    }
    
    var finalizedOutput:Dictionary<String,String> {
        var dict = Dictionary<String,String>()
        dict["bid"] = self.brandID
        dict["bsz"] = String(self.sizeClass)
        dict["qty"] = String(self.todaySale ?? 0)
        dict["conf"] = String(describing: loadoutQty)
        dict["lvl"] = String(self.todayLevel ?? 0.0)
        return dict
    }
}

