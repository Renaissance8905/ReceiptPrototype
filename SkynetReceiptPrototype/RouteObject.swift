//
//  RouteObject.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 5/28/16.
//  Copyright © 2016 Chris Spradling. All rights reserved.
//

import Foundation
import UIKit

class RouteObject {
    
    var routeSheet: [RetailerObject]
    let routeNo: String
    let driver: Driver
    let payments: [String]
    
    var driverID: Int {
        get {return self.driver.driverID}
        set {self.driver.driverID = newValue}
    }
    var driverUsername: String {
        get {return self.driver.username}
        set {self.driver.username = newValue}
    }
    
    fileprivate var invoices: [Int] = [0]
    
    
    let Inventory: BrandPriceInventoryMatrix
    
    
    var brandsInInventory: [String] {return self.Inventory.AvailableBrands}
    
    var brandsOnTruck: [String] {
        return self.Inventory.AvailableBrands.filter({ (brandID) -> Bool in
            return self.Inventory[brandID]!.onTruck
        })
    }
    
    
    
    var loadoutTotal: [Int] {return self.Inventory.loadoutTotal}
    
    var defaultLoadoutTotal: [Int] {return self.Inventory.defaultLoadoutTotal}
    
    var salesTotal: [Int] {return self.Inventory.salesTotal}
    
    var remainingTotal: [Int] {return self.Inventory.RemainingTotal}
    
    var currentWeight: Int {
        return (self.Inventory.RemainingTotal[0] * 165) + (self.Inventory.RemainingTotal[1] * 85) + ((self.Inventory.RemainingTotal[2] + self.Inventory.RemainingTotal[3]) * 21)
    }
    
    
    var drivingBegan = false
    var drivingFinished = false
    
    
    var nextInvoice: Int {
        get {
            self.refillInvoices()
            if invoices.count > 0 {
                return invoices.remove(at: 0)
            }
            return 0
        }
        set {
            if newValue > 0 {
                self.invoices.insert(newValue, at: 0)
            }
        }
    }
    
    var miscSaleItems: [(Int, String, Double)] = []
    
    
    init(jsonData: Dictionary<String,AnyObject>) {
        
        // Status
        let status = jsonData["status"] as? String ?? "FAILED PARSING"
        if status == "OK" {
            
            // Driver
            self.driver = Driver(driverData: jsonData["driver"] as! Dictionary<String,AnyObject>)
            
            // Recovery
            var recoveryData = Dictionary<String,Dictionary<Int,Array<Int>>>()
            if let recoveryRaw = jsonData["recovered_loadout"] as? Dictionary<String,AnyObject> {
                
                for (brand, bData) in recoveryRaw {
                    let bData = bData as! Dictionary<Int,Array<Int>>
                    recoveryData[brand] = [:]
                    for (size, QTYs) in bData {

                        recoveryData[brand]![size] = []
                        for qty in QTYs {
                            recoveryData[brand]![size]!.append((qty))
                        }
                    }
                }
            } else {
                recoveryData = [:]
            }
            // RouteNo
            self.routeNo = jsonData["route"] as! String

            
            // Available Brands
            var brandData = Dictionary<String,Dictionary<String,AnyObject>>()

            if let brandRaw = jsonData["brands"] as? Dictionary<String,AnyObject> {
                for (k, v) in brandRaw {
                    brandData[k] = Dictionary<String,AnyObject>()
                    let value = v as! Dictionary<String,AnyObject>
                    for (valType, val) in value {
                        if valType == "price" {
                            let prices = val as! Dictionary<Int,String>
                            var priceDict = Dictionary<Int,String>()
                            for (code, price) in prices {
                                priceDict[code] = price
                            }
                            brandData[k]![valType] = priceDict as AnyObject?
                            
                        } else {
                            brandData[k]![valType] = val as! String as AnyObject?
                        }
                    }
                }
            } else {
                brandData = [
                    "HW": ["name": "Hefeweizen" as AnyObject, "price": [7: "80.00", 15: "145.00", 6: "28.00"] as AnyObject],
                    "BB": ["name": "Big Bark" as AnyObject, "price": [7: "80.00", 15: "145.00", 6: "28.00"] as AnyObject],
                    "PZ": ["name": "Pilz" as AnyObject, "price": [7: "80.00", 15: "145.00", 6: "28.00"] as AnyObject],
                    "LA": ["name": "Liberation Ale" as AnyObject, "price": [7: "85.00", 15: "155.00"] as AnyObject]
                ]
            }
            
            // Available Sizes
            var sizeData = Dictionary<Int,Dictionary<String,String>>()
            if let sizeRaw = jsonData["sizes"] as? Dictionary<String,Dictionary<String,String>> {
                for (k, v) in sizeRaw {
                    sizeData[(k as NSString).integerValue] = v
                }
            } else {
                sizeData = [
                    15: ["name":"Half", "short":""],
                    7: ["name":"Quarter", "short":".25"],
                    6: ["name":"6-Case", "short":"c6"],
                    12: ["name":"12-Case", "short":"c12"]
                ]
            }
            
            
            self.Inventory = BrandPriceInventoryMatrix(brands: brandData as Dictionary<String, AnyObject>, sizes: sizeData)
            if self.driver.isActive && recoveryData.count > 0 {
                self.Inventory.setBaseLoadout(recoveryData)
            }
            
            
            // Invoices
            if let invoiceRaw = jsonData["invoices"] as? [Int] {
                invoices = invoiceRaw
            }

            // Payments
            self.payments = jsonData["payments"] as? [String] ?? ["COD", "PP", "FINT"]
            
            // Misc Sale Items
            let itemData = jsonData["miscitems"] as! [Dictionary<String,AnyObject>]
            for item in itemData {
                if let id = (item["id"] as? NSString)?.integerValue {
                    if let descr = item["descr"] as? String {
                        if let price = (item["price"] as? NSString)?.doubleValue {
                            self.miscSaleItems.append((id, descr, price))
                        }
                    }
                }
            }
            if self.miscSaleItems.count > 1 {self.miscSaleItems.sort(by: {$0.0 < $1.0})}
            
            
            // Routesheet
            let routeRaw = jsonData["rtelist"] as! Dictionary<String,AnyObject>
            var routeData = Dictionary<String, Dictionary<String,AnyObject>>()
            for (key, value) in routeRaw {
                if let ret = value as? Dictionary<String, AnyObject> {
                    routeData[key] = ret
                }
            }
            self.routeSheet = []
            setRouteSheet(routeData)

            self.setBaseLoadout()
            if self.driver.isActive {self.beginDriving()}
        } else {
            // Failed JSON Import
            self.routeSheet = []
            self.routeNo = ""
            self.payments = []
            self.driver = Driver(driverData: [:])
            self.Inventory = BrandPriceInventoryMatrix(brands: [:], sizes: [:])
        }
    }
    
    
    
    fileprivate func refillInvoices() {
        invoices.append((invoices.last ?? 16000000) + 1)
    }
    
    
    /////////////////////////////////////////
    //                                     //
    //        INITIALIZER FUNCTONS         //
    //                                     //
    /////////////////////////////////////////
    
    func setRouteSheet(_ data: Dictionary<String,Dictionary<String,AnyObject>>) {
        var data = data
        let first:String = self.findFirstRetailer(data)
        if first != "NONE" {
            
            var thisRetailer: RetailerObject = RetailerObject(retailerData: data[first]!, truck: self)
            var next: String = String(describing: data[first]!["successor"]!)
            data.removeValue(forKey: first)
            self.routeSheet.append(thisRetailer)
            
            // work through chain as far as possible
            while next != "0" && data[next] != nil {
                
                thisRetailer = RetailerObject(retailerData: data[next]!, truck: self)
                self.routeSheet.append(thisRetailer)
                next = String(describing: data[next]!["successor"]!)
                data.removeValue(forKey: String(thisRetailer.id))
                
            }
        }
        
        // Append stops that didn't fit in order
        // Or append all stops if firstFinder returned an error
        for (_, value) in data {
            let retailerData = value
            self.routeSheet.append(RetailerObject(retailerData: retailerData, truck: self))
        }
        
    }
    
    
    fileprivate func findFirstRetailer(_ dict: Dictionary<String, Dictionary<String, AnyObject>>) -> String {
        var retailers: [String] = []
        var successors: [String] = []
        
        // Find all retailers with predecessor stop of 0
        for (key, value) in dict {
            if String(describing: value["predecessor"]) == "0" {
                retailers.append(key)
                successors.append(String(describing: value["successor"]))
            }
        }
        
        // Check for rogue opener stops
        if retailers.count > 1 {
            for i in (0...retailers.count-1) {
                if dict[successors[i]] != nil {
                    // returns first viable retailer id
                    // ********(look here if problems arise)******
                    return retailers[i]
                }
            }
        }
        // Error: no retailers found
        else if retailers.count == 0 {
            return "NONE"
        }
        // Hopefully single retailer found, return its id
        return retailers[0]
    }
    
    
    
    
    /////////////////////////////////////////
    //                                     //
    //        RETAILER MANIPULATION        //
    //                                     //
    /////////////////////////////////////////
    
    
    func append(_ retailer: RetailerObject, saveOrder: Bool, affectsLoadout:Bool?=true) {
        if saveOrder == true && self.routeSheet.count > 0 {
            let lastRet = self.routeSheet.last!
            lastRet.successorStop = retailer
            retailer.predecessorStop = lastRet
            retailer.successorStop = nil
        }
        self.routeSheet.append(retailer)
        
        if self.drivingBegan == false && affectsLoadout == true {
            bulkAlterLoadout(retailer.onTapAtThisStop, decrement: false, affectsDefault: true)
        }
    }
    
    
    func addRetailerAtIndex(_ retailer: RetailerObject, idx: Int, saveOrder: Bool, affectsLoadout:Bool?=true) {
        self.routeSheet.insert(retailer, at: idx)
        //wedge moved retailer into route chain
        if self.routeSheet.count > 2 && saveOrder == true {
            if idx == 0 {
                retailer.predecessorStop = nil
                retailer.successorStop = self.routeSheet[idx+1]
                self.routeSheet[idx+1].predecessorStop = retailer
            } else if idx == self.routeSheet.count-1 {
                retailer.successorStop = nil
                retailer.predecessorStop = self.routeSheet[idx-1]
                self.routeSheet[idx-1].successorStop = retailer
            } else {
                self.routeSheet[idx-1].successorStop = retailer
                retailer.predecessorStop = self.routeSheet[idx-1]
                retailer.successorStop = self.routeSheet[idx+1]
                self.routeSheet[idx+1].predecessorStop = retailer
            }
        }
        if self.drivingBegan == false && affectsLoadout == true {
            bulkAlterLoadout(retailer.onTapAtThisStop, decrement: false, affectsDefault: true)
        }
    }
    
    
    func removeRetailerAtIndex(_ retailer: RetailerObject, idx: Int, saveOrder: Bool, affectsLoadout:Bool = true) {
        
        self.routeSheet.remove(at: idx)
        
        //close hole in route chain
        if self.routeSheet.count > 2 && saveOrder {
            switch idx {
            case 0:
                self.routeSheet[idx].predecessorStop = nil
            case self.routeSheet.count:
                self.routeSheet[idx-1].successorStop = nil
            default:
                self.routeSheet[idx-1].successorStop = self.routeSheet[idx]
                self.routeSheet[idx].predecessorStop = self.routeSheet[idx-1]
            }
        }
        if !self.drivingBegan && affectsLoadout {
            bulkAlterLoadout(retailer.onTapAtThisStop, decrement: true, affectsDefault: true)
        }
    }
    
    
    func moveRetailerByIndex(_ from: Int, to: Int, save: Bool) {
        if to == from {
            return
        }
        let retailer = self.routeSheet[from]
        self.removeRetailerAtIndex(retailer, idx: from, saveOrder: true, affectsLoadout: false)
        self.addRetailerAtIndex(retailer, idx: to, saveOrder: true, affectsLoadout: false)
    }
    
    
    
    
    /////////////////////////////////////////
    //                                     //
    //         BRAND  MANIPULATION         //
    //                                     //
    /////////////////////////////////////////
    
    
    func addBrand(_ retailer: RetailerObject, brand: OnSiteBrand, wasSold:Bool=false) {
        retailer.onTapAtThisStop.append(brand)
        self.incrementLoadout(brand, quantity: brand.loadoutQty, affectsDefault: true)
        if wasSold {self.recordSale(brand)}
    }
    
    
    func removeBrand(_ retailer: RetailerObject, brandIdx: Int) {
        let offendingBrand = retailer.onTapAtThisStop.remove(at: brandIdx)
        self.decrementLoadout(offendingBrand, quantity: offendingBrand.loadoutQty, affectsDefault: true)
    }
    
    
    
    /////////////////////////////////////////
    //                                     //
    //        LOADOUT  MANIPULATION        //
    //                                     //
    /////////////////////////////////////////
    
    fileprivate func bulkAlterLoadout(_ brands: [OnSiteBrand], decrement: Bool?=false, affectsDefault: Bool?=false) {
        for brand in brands {
            switch decrement! {
            case true:
                self.decrementLoadout(brand, quantity: brand.loadoutQty, affectsDefault: affectsDefault!)
            case false:
                self.incrementLoadout(brand, quantity: brand.loadoutQty, affectsDefault: affectsDefault!)
            }
        }
    }
    
    
    func setBaseLoadout() {
        for ret in routeSheet {
            for brand in ret.onTapAtThisStop {
                incrementLoadout(brand, quantity: brand.loadoutQty, affectsDefault: true)
            }
        }
    }
    
    
    // WARNING: sets value of single loadout item directly
    // To +/- loadout item by an amount, use incrementLoadout and decrementLoadout
    private func alterLoadout(_ brandID: String, sizeidx: Int, quantity: Int) {
        if !self.drivingBegan {
            self.Inventory[brandID]?[indexToSize(sizeidx)]?.Loadout = quantity
        }
    }
    
    
    func alterSalesTally(_ brand: OnSiteBrand, decrement: Bool=false) {
        if decrement {
            self.Inventory[brand]!.Sales -= brand.todaySale ?? 0
        } else {
            self.Inventory[brand]!.Sales += brand.todaySale ?? 0
        }
        
    }
    
    
    func recordSale(_ brand: OnSiteBrand) {
        if !brand.saleRecorded {
            alterSalesTally(brand)
            brand.saleRecorded = true
        }
    }
    
    
    func deleteSale(_ brand: OnSiteBrand) {
        if brand.saleRecorded {
            alterSalesTally(brand, decrement: true)
            brand.saleRecorded = false
        }
    }
    
    
    func decrementLoadout(_ brand: OnSiteBrand, quantity: Int, affectsDefault:Bool=false, forceUpdate:Bool=false) {
        
        if !self.drivingBegan || forceUpdate {
            if affectsDefault {
                self.Inventory[brand]!.DefaultLoadout -= quantity
            } else {
                self.Inventory[brand]!.overrideLockedLoadoutSubtract(quantity)
            }
        }
    }
    
    
    func incrementLoadout(_ brand: OnSiteBrand, quantity: Int, affectsDefault:Bool=false, forceUpdate:Bool=false) {
        
        if !self.drivingBegan || forceUpdate {
            if affectsDefault {
                self.Inventory[brand]!.DefaultLoadout += quantity
            } else {
                self.Inventory[brand]!.overrideLockedLoadoutAdd(quantity)
            }
        }
    }
    
    
    func resetToDefaultLoadout() {
        self.Inventory.resetToDefaultLoadout()
    }
    
    
    func beginDriving() {
        self.drivingBegan = true
        self.driver.drivingBegan()
    }
    
    
    
    
    /////////////////////////////////////////
    //                                     //
    //         AUXILIARY FUNCTIONS         //
    //                                     //
    /////////////////////////////////////////
    
    
    subscript(idx: Int) -> RetailerObject {
        get {return self.routeSheet[min(idx, self.routeSheet.count - 1)]}
        set {self.routeSheet[idx] = newValue}
    }
    
    
    var listOfBrandsOnTruck: [String] {return self.brandsOnTruck}
 
    
    func retailerIDs() -> Data? {
        var list: [Int] = []
        for item in self.routeSheet {
            list.append(item.id)
        }
        do {return try JSONSerialization.data(withJSONObject: list, options: [])}
        catch {return nil}
    }
    
    func jsonizedLoadout() -> Data? {
        var list: Array<NSDictionary> = []
        let sizes = [15,7,6,12]
        for (key, value) in self.Inventory.matrix {
            for i in sizes {
                if value.sizes[i]!.Loadout > 0 {
                    list.append([
                            "brand":key,
                            "size":String(i),
                            "qty":String(value.sizes[i]?.Loadout ?? 0),
                            "avail":String(value.sizes[i]?.MaxSale ?? 0)
                            ] as NSDictionary)
                }
            }
        }
        do{
            return try JSONSerialization.data(withJSONObject: list, options: [])
        }
        catch {return nil}
    }
    
    var retailersByID: [String] {
        var ids: [String] = []
        for ret in self.routeSheet {
            if let _ = ret.id as Int! {
                ids.append(String(ret.id))
            }
        }
        return ids
    }
}





//
// MARK:-- Printer setup for Load-In Check Receipt
//
extension RouteObject {
        
    fileprivate func printLoadInFooter(zplh: ZPLHelper) {
        zplh.drawHorizontalLine(thickness: 5)
        
        zplh.moveCursorBy(x: 50, y: 40)
        zplh.drawBox(thickness: 3, w: 40, h: 40)
        zplh.moveCursorBy(x: 60, y: 10)
        zplh.addText(text: "On Truck", fontHeight: 30)
        
        zplh.moveCursorBy(x: 50-zplh.cursorX, y: 70)
        zplh.drawBox(thickness: 3, w: 40, h: 40)
        zplh.moveCursorBy(x: 60, y: 10)
        zplh.addText(text: "In Warehouse", fontHeight: 30)
        
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+70)
        zplh.drawHorizontalLine(thickness: 5)
        
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+160)
        zplh.drawHorizontalLine(thickness: 1)
        zplh.moveCursorBy(x: 0, y: 5)
        zplh.addText(text: "Receiver Signature", fontHeight: 15)
        
        
        zplh.moveCursorTo(x: 0, y: zplh.cursorY+160)
        zplh.drawHorizontalLine(thickness: 1)
        zplh.moveCursorBy(x: 0, y: 5)
        zplh.addText(text: "Driver Signature", fontHeight: 15)
    }
    
    
    fileprivate func printLoadInItems(zplh: ZPLHelper) {
        
        for (name, brand) in self.Inventory.matrix.filter({
            for (_, size) in $0.value.sizes {
                if size.Remainder > 0 { return true }
            }
            return false
        }).sorted(by: { return $0.key < $1.key }) {
            
            zplh.addText(text: name.uppercased(), fontHeight: 30)
            zplh.moveCursorBy(x: 60, y: 30)
            
            for (size, obj) in brand.sizes.sorted(by: {
                return [15, 7, 6, 12].index(of: $0.key) ?? 0 < [15, 7, 6, 12].index(of: $1.key) ?? 0
            }) {
                let qty = obj.Remainder
                if qty > 0 || [15, 7].contains(size) {

                    var pad: Int = 280
                    if qty >= 1000 { pad -= 13 }
                    if qty >= 100 { pad -= 13 }
                    if qty >= 10 { pad -= 13 }
                    
                    zplh.addText(text: obj.sizeName, fontHeight: 28)
                    zplh.moveCursorBy(x: pad, y: 0)
                    zplh.addText(text: qty > 0 ? String(qty) : "-", fontHeight: 28)
                    zplh.moveCursorBy(x: 60-zplh.cursorX, y: 28)
                }
            }
            zplh.moveCursorTo(x: 0, y: zplh.cursorY+40)
        }
    }
    
    
    fileprivate var loadInLengthCounter: Int {
        var len = 950
        for (_, brand) in self.Inventory.matrix.filter({
            for (_, size) in $0.value.sizes {
                if size.Remainder > 0 { return true }
            }
            return false
        }) {
            len += 126 // 70 for brand label + 28 each for halves & quarters (which always display)
            if brand.sizes[6]?.Remainder ?? 0 > 0 { len += 28 }
            if brand.sizes[12]?.Remainder ?? 0 > 0 { len += 28 }
        }
        return len
    }
    
    
    
    fileprivate func printLoadInHeader(zplh: ZPLHelper) {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MM/dd/yy hh:mm a"
        
        zplh.moveCursorBy(x: 0, y: 10)
        zplh.addText(text: self.driver.truck_name ?? "Truck: ___________", fontHeight: 40)
        zplh.moveCursorBy(x: 0, y: 45)
        zplh.addText(text: formatter.string(from: NSDate() as Date), fontHeight: 30)
        zplh.moveCursorBy(x: 0, y: 40)
        zplh.addText(text: "DRIVER: \(self.driver.driverName ?? "______")", fontHeight: 30)
        zplh.moveCursorBy(x: 95, y: 60)
        zplh.addText(text: "REMAINDER", fontHeight: 35)
        zplh.moveCursorBy(x: -95, y: 35)
        zplh.drawHorizontalLine(thickness: 5)
        zplh.moveCursorBy(x: 0, y: 40)
    }
    
    
    
    
    func printLoadInCheck(delegate: PrinterManagerDelegate) {
        // at font height 30, 10 spaces = 8 characters.
        // 1 char = 1.25 space ; 1 space = .8 char
        
        let zplh = ZPLHelper(labelWidth: 400, labelLength: self.loadInLengthCounter)
        let pm = PrinterManager(delegate: delegate)
        
        printLoadInHeader(zplh: zplh)
        
        printLoadInItems(zplh: zplh)
        
        printLoadInFooter(zplh: zplh)
        
        zplh.finish()
        pm.commands = zplh.getCommands()
        pm.print()
        zplh.commands = ""
    }
}
