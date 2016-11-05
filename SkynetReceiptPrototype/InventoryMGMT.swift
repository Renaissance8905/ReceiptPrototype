//
//  InventoryMGMT.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 8/29/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation
import UIKit
import MapKit


class PackageSize: CustomStringConvertible {
    fileprivate let ref_brand: Brand
    let sizeCode: Int
    let shorthand: String
    let Price: Double
    
    var sizeName: String {
        switch self.sizeCode {
        case 15: return "Half"
        case 7: return "Quarter"
        case 6: return "6-Case"
        case 12: return "12-Case"
        default: return ""
        }
    }
    
    // Publicly-viewable Loadout can never be less than 0 or the Confirmed, whichever is greater
    var DefaultLoadout: Int = 0
    fileprivate var PaddedDefault: Int {return Int(ceil(Double(DefaultLoadout) * ref_brand.matrix.paddingPercent))}
    fileprivate var LoadoutAdjust: Int = 0
    
    var Loadout: Int {
        get {return max(PaddedDefault + LoadoutAdjust, Confirmed)}
        set {
            if !self.ref_brand.matrix.loadoutLocked {
                LoadoutAdjust = max(newValue, 0, Confirmed) - PaddedDefault
            }
        }
    }

    fileprivate var sales: Int = 0
    var Sales: Int {
        get {return self.sales}
        set {self.sales = max(newValue, 0)}
    }
    
    fileprivate var confirmed: Int = 0
    var Confirmed: Int {
        get {return confirmed}
        set {confirmed = max(newValue, 0)}
    }
    
    var Remainder: Int {return self.Loadout - self.Sales}
    var MaxSale: Int {return self.Remainder - self.Confirmed}
    let description: String
    
    
    init(brand: Brand, code: Int, name: String, abbr: String, price: Double, initial_load: Int?=0) {
        self.sizeCode = code
        self.description = "\(brand): \(name)"
        self.shorthand = "\(brand.brandID)\(abbr)"
        self.Price = price
        self.ref_brand = brand
        
        if initial_load != nil {
            self.DefaultLoadout = initial_load!
            self.Loadout = initial_load!
        }
    }
    
    fileprivate func resetToDefaultLoadout() {
        self.LoadoutAdjust = 0
    }
    
    func overrideLockedLoadoutAdd(_ qty: Int) {
        LoadoutAdjust += qty
    }
    func overrideLockedLoadoutSubtract(_ qty: Int) {
        LoadoutAdjust = max(LoadoutAdjust - qty, Confirmed - PaddedDefault)
    }
    
}



class Brand: CustomStringConvertible {
    
    let brandID: String
    fileprivate let matrix: BrandPriceInventoryMatrix
    var sizes: Dictionary<Int, PackageSize>
    fileprivate var appendedToTruck: Bool = false
    
    let description: String
    let inStock: Bool
    
    init(id: String, fullname: String, available: Bool, matrix: BrandPriceInventoryMatrix) {
        self.brandID = id
        self.description = fullname
        self.inStock = available
        self.sizes = [:]
        self.matrix = matrix
    }
    
    subscript(size: Int) -> PackageSize? {
        return self.sizes[size] ?? nil
//        return self.sizes[size] ?? PackageSize(brand: self, code: 0, name: "ERROR", abbr: "ERR", price: 0.0)

//        if self.sizes.keys.contains(size) {
//            return self.sizes[size]!
//        } else {
//            return PackageSize(brand: self, code: 0, name: "ERROR", abbr: "ERR", price: 0.0)
//        }
    }

    var onTruck: Bool {
        if appendedToTruck {return true}
        for (_, size) in sizes {
            if size.DefaultLoadout + size.Loadout > 0 {return true}
        }
        return false
    }

    fileprivate func resetToDefaultLoadout() {
        self.appendedToTruck = false
        for (_, item) in sizes {
            item.resetToDefaultLoadout()
        }
    }
    
    var availableSizeNames: [String] {
        var sizes: [String] = []
        for size in availableSizes {
            sizes.append(size.sizeName)
        }
        return sizes
    }

    var availableSizes: [PackageSize] {
        var sizes: [PackageSize] = []
        for (_, pkg) in self.sizes {
            if !(self.matrix.loadoutLocked || pkg.Price == 0) || pkg.Loadout > 0 {
                sizes.append(pkg)
            }
        }
        return sizes.sorted(by: {
            if $0.sizeName == "Half" {return true}
            if $1.sizeName == "Half" {return false}
            return $0.description > $1.description            
        })
    }
    
    var loadoutRowArray: [Int] {
        return [
            (self.sizes[15]?.Loadout) ?? 0,
            (self.sizes[7]?.Loadout) ?? 0,
            (self.sizes[6]?.Loadout) ?? 0,
            (self.sizes[12]?.Loadout) ?? 0
        ]
    }
    
    func appendToTruck() {
        appendedToTruck = true
    }
}

class BrandPriceInventoryMatrix {
    // matrix["HW"][7].Price = 80.00
    // matrix["HW"][7].Loadout = 10
    // matrix["HW"][7].Sales = 4
    // matrix["HW"][7].Remainder = 6
    // matrix["HW"][7].Display = "Hefeweizen: Quarter"
    
    // matrix["HW"].Name = "Hefeweizen"
    
    var matrix = Dictionary<String, Brand>()
    var AllBrands = [String]()
    var AvailableSizes = [Int]()
    
    var AvailableBrands: [String] {
        return self.AllBrands.filter({
            self.matrix[$0]?.inStock ?? false
        })
    }
    
    var paddingPercent: Double = 1.0
    var loadoutLocked: Bool {return UserDefaults.standard.bool(forKey: "drivingBegan")}
    
    
    init(brands: Dictionary<String, AnyObject>, sizes: Dictionary<Int,Dictionary<String,String>>) {
        
        for (key, _) in sizes {
            self.AvailableSizes.append(key)
        }
        
        for (key, value) in brands {
            self.AllBrands.append(key)
            let info = value as! Dictionary<String,AnyObject>
            let b_name = info["name"] as! String
            let prices = info["price"] as! Dictionary<Int,String>
            let available = info["instock"] as? String == "1"
            let new_brand = Brand(id: key, fullname: b_name, available: available, matrix: self)
            
            for (code, info) in sizes {
                let price = prices[code] ?? "0"
                new_brand.sizes[code] = PackageSize(brand: new_brand, code: code, name: info["name"]!, abbr: info["short"]!, price: (price as NSString).doubleValue)
            }
            
            self.matrix[key] = new_brand
            self.AllBrands.sort(by: {
                self.matrix[$0]!.brandID < self.matrix[$1]!.brandID
            })
            self.AvailableSizes.sort(by: {
                sizeToIndex($0) < sizeToIndex($1)
            })
            
        }
    }
    
    subscript(brandID: String) -> Brand? {
        return self.matrix[brandID] ?? nil
        
        
//        return self.matrix[brandID] ?? Brand(id: "", fullname: "ERROR", matrix: self)
//        if self.matrix.keys.contains(brandID) {
//            return self.matrix[brandID]!
//        }
//        return Brand(id: "", fullname: "ERROR", matrix: self)
    }
    
    subscript(brand: OnSiteBrand) -> PackageSize? {
        return self[brand.brandID]?[brand.sizeClass] ?? nil
    }
    
    func setBaseLoadout(_ load: Dictionary<String,Dictionary<Int,Array<Int>>>) {
        for (key, value) in load {
            if self.AvailableBrands.contains(key) {
                for (size, qty) in value {
                    if self.AvailableSizes.contains(size) {
                        self[key]?[size]?.Loadout = qty[0]
                    }
                }
            }
        }
    }
    
    var loadout: Dictionary<String, Array<Int>> {
        var dict = Dictionary<String, Array<Int>>()
        for (id, brand) in self.matrix {
            if brand.onTruck {
                dict[id] = brand.loadoutRowArray
            }
        }
        return dict
    }
    
    func resetToDefaultLoadout() {
        for (_, item) in self.matrix {
            item.resetToDefaultLoadout()
        }
    }
    
    var loadoutTotal: [Int] {
        var total = [0,0,0,0]
        for (_, value) in self.matrix {
            let sizes = value.sizes
            total[0] += (sizes[15]?.Loadout) ?? 0
            total[1] += (sizes[7]?.Loadout) ?? 0
            total[2] += (sizes[6]?.Loadout) ?? 0
            total[3] += (sizes[12]?.Loadout) ?? 0
        }
        return total
    }
    
    var defaultLoadoutTotal: [Int] {
        var total = [0,0,0,0]
        for (_, value) in self.matrix {
            let sizes = value.sizes
            total[0] += (sizes[15]?.DefaultLoadout) ?? 0
            total[1] += (sizes[7]?.DefaultLoadout) ?? 0
            total[2] += (sizes[6]?.DefaultLoadout) ?? 0
            total[3] += (sizes[12]?.DefaultLoadout) ?? 0
        }
        return total
    }

    var salesTotal: [Int] {
        var total = [0,0,0,0]
        for (_, value) in self.matrix {
            let sizes = value.sizes
            total[0] += (sizes[15]?.Sales) ?? 0
            total[1] += (sizes[7]?.Sales) ?? 0
            total[2] += (sizes[6]?.Sales) ?? 0
            total[3] += (sizes[12]?.Sales) ?? 0
        }
        return total
    }


    var RemainingTotal: [Int] {
        var total = loadoutTotal
        for (_, value) in self.matrix {
            let sizes = value.sizes
            total[0] -= (sizes[15]?.Sales) ?? 0
            total[1] -= (sizes[7]?.Sales) ?? 0
            total[2] -= (sizes[6]?.Sales) ?? 0
            total[3] -= (sizes[12]?.Sales) ?? 0
        }
        return total
    }
}
