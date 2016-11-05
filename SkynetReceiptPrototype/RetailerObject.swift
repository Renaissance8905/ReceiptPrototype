//
//  RetailerObject.swift
//  Skynet Mk4a
//
//  Created by Christopher Spradling on 6/30/15.
//  Copyright (c) 2015 Live Oak. All rights reserved.
//

import Foundation
import UIKit
import MapKit






class RetailerObject {
    
    let parentTruck: RouteObject
    
    // State Controllers
    var allBrandsChecked: Bool {
        for item in self.onTapAtThisStop {
            if !item.complete {return false}
        }
        return true
    }
    
    var saleMade: Bool {
        if !salePosted {return false}
        for item in self.onTapAtThisStop {
            if item.todaySale ?? 0 > 0 {return true}
        }
        return false
    }
    
    var saleToMake: Bool {
        if salePosted {return false}
        for item in self.onTapAtThisStop {
            if item.todaySale ?? 0 > 0 {return true}
        }
        return false

    }
    
    var salePosted: Bool = false
    var checkNumber: Int?
    var cash: Bool?
    
    var signature: UIImage?
    var signatureFilename: String?
    var invoice: Int?
    
    
    // Core Properties
    var id: Int
    var retailerName: String
    var tabc: String
    var route: String
    var region: String?
    var payType: String
    
    var successorStop: RetailerObject? = nil
    var predecessorStop: RetailerObject? = nil
    
    // Brands (as array of Brand Objects)
    var onTapAtThisStop: [OnSiteBrand] = []
    
    // Sale Properties
    var kegCredits: Int = 0
    var extraItemsForSale: [(Int, String, Double, Int)] = []
    
    
    init(retailerData: Dictionary<String, AnyObject>, truck: RouteObject) {
        
        self.parentTruck = truck
        
        self.id = (retailerData["id"] as? NSString)!.integerValue

        self.retailerName = retailerData["name"] as! String
        self.tabc = retailerData["tabc"] as! String
        self.route = retailerData["route"] as? String ?? ""
        self.region = retailerData["region"] as? String ?? nil
        self.payType = retailerData["payment"] as? String ?? "COD"


        if let brandDataArray = retailerData["brandDataArray"] as? Dictionary<String, AnyObject> {
            for (_, value) in brandDataArray {
                let newBrand = OnSiteBrand(data: value as! Dictionary<String, AnyObject>, retailer: self)
                self.onTapAtThisStop.append(newBrand)
            }
        }

        self.invoice = ((retailerData["invoice"] as? NSString)?.integerValue) ?? nil
        if let chk = retailerData["chknum"] as? NSString {
            self.cash = chk == "CASH"
            self.checkNumber = chk.integerValue != 0 ? chk.integerValue : nil
        }
        
        
    }
    
    
    var stringLoadout: String {
        var txt = ""
        for brand in self.onTapAtThisStop {
            let qty = String(brand.loadoutQty)
            let id = brand.brandShorthand
            txt = ("\(txt)   \(qty)x\(id)\n")
        }
        return txt
    }
    
    var allSales: [OnSiteBrand] {
        return self.onTapAtThisStop.filter({ (brand) -> Bool in
            return brand.complete && brand.todaySale != nil && brand.todaySale ?? 0 > 0
        })
    }
    
    
    var volumeForDiscount: Double {
        var count = 0.0
        for brand in allSales {
            switch brand.sizeClass {
            case 15: count += Double(brand.todaySale!)
            case 7: count += Double(brand.todaySale!) / 2
            default: ()
            }
        }
        return count
    }
    
    
    var volumeDiscountLevel: Double {
        switch Int(volumeForDiscount) {
        case (3...4): return 5
        case (5...9): return 10
        case (10...1000): return 15
        default: return 0
        }
    }
    
    
    var volumeDiscountValue: Double {
        return volumeForDiscount * Double(volumeDiscountLevel)
    }
    
    
    func retrieveInvoice(_ callback: (String) -> ()) {
        self.invoice = self.invoice ?? self.parentTruck.nextInvoice
        callback(String(self.invoice!))
    }
    
    
    var kegDepositQuantity: Int {
        var count = 0
        for brand in allSales {
            count += [15, 7].contains(brand.sizeClass) ? brand.todaySale! : 0
        }
        return count
    }
    
    
    var totalSalePrice: Double {
        var price = 0.0
        
        // Tally gross sales
        for item in allSales {
            price += (Double(item.todaySale!) * item.price)
        }
        
        // Add net keg deposit
        price += (Double(kegDepositQuantity - kegCredits) * 30)
        
        // Subtract volume discount
        price -= volumeDiscountValue
        
        // Add extra items
        for extra in extraItemsForSale {
            price += (Double(extra.3) * extra.2)
        }
        
        return price
    }

    
    func finalOutput() -> Dictionary<String,AnyObject> {
        var outDict = Dictionary<String,AnyObject>()
        
        outDict["driver"] = String(self.parentTruck.driverID) as AnyObject?
        outDict["ret"] = self.id as AnyObject?
        outDict["invoice"] = String(invoice!) as AnyObject?
        outDict["keg_cred"] = String(self.kegCredits) as AnyObject?
        outDict["pay"] = self.payType as AnyObject?
        if checkNumber != nil {
            outDict["chk"] = String(checkNumber!) as AnyObject?
        }
        else if cash == true {
            outDict["chk"] = "CASH" as AnyObject?
        }
        outDict["voldisc"] = String(self.volumeDiscountValue) as AnyObject?
        outDict["total"] = String(self.totalSalePrice) as AnyObject?
        
        var sales: [[String: String]] = []
        for brnd in onTapAtThisStop {
            sales.append(brnd.finalizedOutput)
        }
        outDict["sales"] = sales as AnyObject?
        
        var misc: [[String: String]] = []
        for item in extraItemsForSale {
            misc.append(["id":String(item.0),"qty":String(item.3)])
        }
        outDict["misc"] = misc as AnyObject?
        
        outDict["sigtitle"] = self.signatureFilename as AnyObject?? ?? "noname" as AnyObject?
        
        return outDict
        
    }
    
    func commitSale() {

        self.salePosted = true
        
        for brand in allSales {
            self.parentTruck.recordSale(brand)
        }
        
    }
    
}








extension RetailerObject {
    
    func padForPrice(base: Int, price: Double) -> Int {
        var pad = price < 0 ? base - 18 : base
        let p = abs(price)
        if p >= 10 { pad -= 8 }
        if p >= 100 { pad -= 8 }
        if p >= 1000 { pad -= 8 }
        return pad
    }
    
    func padForTotalPrice(price: Double) -> Int {
        var pad = 325
        let p = abs(price)
        if p >= 10 { pad -= 12 }
        if p >= 100 { pad -= 12 }
        if p >= 1000 { pad -= 12 }
        return pad
    }
    
    
    func gatherSaleItems() -> [(Double, String, Double)] {
        var items: [(Double, String, Double)] = []
        
        // Add sold brands
        for brand in allSales {
            if brand.todaySale ?? 0 > 0 {
                items.append((Double(brand.todaySale!), brand.brandShorthand, brand.price))
            }
        }
        
        // Add keg deposit
        if self.kegDepositQuantity > 0 {
            items.append((Double(self.kegDepositQuantity), "Keg Deposit", 30))
        }
        
        // Add keg credit
        if self.kegCredits > 0 {
            items.append(((Double(self.kegCredits), "Keg Credit", -30)))
        }
        
        // Add volume discount
        if self.volumeDiscountValue > 0 {
            items.append((self.volumeForDiscount, "Volume Discount", 0-self.volumeDiscountLevel))
        }
        
        // Add misc items
        for (_, name, price, qty) in self.extraItemsForSale {
            items.append((Double(qty), name, price))
        }
        
        return items
        
    }
    
    
    
    func printTotalPrice(zplh: ZPLHelper) {
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+20)
        zplh.addText(text: "TOTAL:", fontHeight: 25)
        zplh.moveCursorBy(x: padForTotalPrice(price: self.totalSalePrice), y: 0)
        zplh.addText(text: String(format: "$%.2f", arguments: [self.totalSalePrice]), fontHeight: 25)
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+35)
        zplh.addText(text: "Payment: \(self.payType)", fontHeight: 20)
        zplh.moveCursorBy(x: 0, y: 20)
        if self.payType == "COD" {
            if self.cash == true {
                zplh.addText(text: "Paid Cash", fontHeight: 20)
            } else if let chk = self.checkNumber {
                zplh.addText(text: "Check #\(chk)", fontHeight: 20)
            } else {
                zplh.addText(text: "Check #:", fontHeight: 20)
            }
        }
    }
    
    
    func printLOBCbio(zplh: ZPLHelper) {
        zplh.moveCursorBy(x: 15, y: 10)
        zplh.addText(text: "LIVE OAK BREWING CO.", fontHeight: 35)
        zplh.moveCursorBy(x: -15, y: 45)
        zplh.addText(text: "1615 Crozier Ln                  (512) 385-2299", fontHeight: 20)
        zplh.moveCursorBy(x: 0, y: 20)
        zplh.addText(text: "Austin, TX 78617            liveoakbrewing.com", fontHeight: 20)
//////////////////////////////////////
        /////// NEEDS TESTING ////////
        //////////////////////////////
        zplh.moveCursorBy(x: 100, y: 30)
        zplh.addText(text: "BA924168", fontHeight: 20)
        zplh.moveCursorBy(x: 0, y: 20)
        zplh.addText(text: "B 924167", fontHeight: 20)
//////////////////////////////////////
        zplh.moveCursorBy(x: 0, y: 30)
        zplh.drawHorizontalLine(thickness: 2)
        zplh.moveCursorBy(x: 0, y: 20)
    }
    
    
    func printInvoiceBio(zplh: ZPLHelper) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        let date = formatter.string(from: NSDate() as Date)
        zplh.addText(text: "INVOICE: \(self.invoice ?? 0)                        \(date)", fontHeight: 20)
        zplh.moveCursorBy(x: 0, y: 30)
        zplh.addText(text: "RETAILER:                                 \(self.tabc)", fontHeight: 20)
        zplh.moveCursorBy(x: 0, y: 20)
        zplh.addWrappingText(text: self.retailerName, fontHeight: 20)
        
        zplh.moveCursorBy(x: 0, y: 20 + Int(20 * ceil(Double(self.retailerName.characters.count) / 38)))
        zplh.addText(text: "SELLER: \(self.parentTruck.driver.driverName ?? "_____")", fontHeight: 20)
        
        zplh.moveCursorBy(x: 0, y: 30)
        zplh.drawHorizontalLine(thickness: 4)
        zplh.moveCursorBy(x: 10, y: 40)
    }
    
    
    func printLineItems(zplh: ZPLHelper) {
        for (qty, name, price) in self.gatherSaleItems() {
            
            let qPrice: Double = qty * price
            
            zplh.addText(text: name, fontHeight: 20)
            zplh.moveCursorTo(x: padForPrice(base: 320, price: qPrice), y: zplh.cursorY)
            zplh.addText(text: String(format: "$%.2f", arguments: [qPrice]), fontHeight: 20)
            zplh.moveCursorTo(x: 30, y: zplh.cursorY+22)
            zplh.addText(text: String(format: "\(qty) @ $%.2f", arguments: [price]), fontHeight: 20)
            zplh.moveCursorTo(x: 10, y: zplh.cursorY+30)

        }
        zplh.moveCursorBy(x: -10, y: 20)
        zplh.drawHorizontalLine(thickness: 4)
    }

    
    
    func printFooter(zplh: ZPLHelper, customerCopy:Bool=false) {
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+160)
        zplh.drawHorizontalLine(thickness: 1)
        zplh.moveCursorBy(x: 0, y: 5)
        zplh.addText(text: "Customer Signature", fontHeight: 15)
        zplh.moveCursorBy(x: 125, y: 60)
        zplh.addText(text: customerCopy ? "Customer Copy" : " Brewery Copy", fontHeight: 20)
    }
    
    
    func dynamicLabelLength() -> Int {
        return 700 + (self.gatherSaleItems().count * 52)
    }
    

    func printReceipt(delegate: PrinterManagerDelegate) {
        print("printing for \(self.retailerName)")
        let zplh = ZPLHelper(labelWidth: 400, labelLength: dynamicLabelLength())
        let pm = PrinterManager(delegate: delegate)
        // LOBC Bio
        printLOBCbio(zplh: zplh)
        // Invoice Bio
        printInvoiceBio(zplh: zplh)
        // Line items
        printLineItems(zplh: zplh)
        // Totals
        printTotalPrice(zplh: zplh)
        // Signature and Footer
        printFooter(zplh: zplh, customerCopy: false)
        
        zplh.finish()
        pm.commands = zplh.getCommands()
        pm.print()
        zplh.reset()
        
        let dupe = UserDefaults.standard.integer(forKey: "dupereceipts")
        if dupe == 2 || (dupe == 1 && self.payType == "COD") {
            printLOBCbio(zplh: zplh)
            printInvoiceBio(zplh: zplh)
            printLineItems(zplh: zplh)
            printTotalPrice(zplh: zplh)
            printFooter(zplh: zplh, customerCopy: true)
            
            zplh.finish()
            pm.commands = zplh.getCommands()
            pm.print()
            zplh.reset()
        }
    }
}


