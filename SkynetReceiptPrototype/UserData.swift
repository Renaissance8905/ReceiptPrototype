//
//  UserData.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 5/27/16.
//  Copyright © 2016 Chris Spradling. All rights reserved.
//

import Foundation
import UIKit

class Driver: ProtoDriver {
    //    “driver”: {
    //        “id” = INT;
    //        “username” = STRING;
    //        “truck” = STRING;
    //        “truck_cap” = INT;
    //        “active” = BOOL;
    //        “active_since” = INT?;
    //    },
    
    var username: String = ""
    var driverName: String?
    var truck_name: String? = nil
    var weight_cap: Int? = nil
    var truckWasAssigned: Bool = false
    var vol_cap: Int? = nil
    var active_since: Date? = nil
    
    var previouslyActiveRoute: String? = nil
    var selectedRoute: String? = nil
    var assignedRoute: String? = nil
    
    init(driverData: Dictionary<String,AnyObject>) {
        super.init()
        username = driverData["username"] as? String ?? ""
        if let actv = driverData["activesince"]?.doubleValue {
            self.active_since = Date(timeIntervalSince1970: actv)
        }
        self.driverID = driverData["id"] as? Int ?? 0
        self.truck_name = (driverData["truck"] as? String) ?? nil
        self.truckWasAssigned = {self.truck_name != nil}()
        self.weight_cap = (driverData["truckwtcap"] as? Int) ?? nil
        self.vol_cap = (driverData["truckvolcap"] as? Int) ?? nil
        self.driverName = (driverData["name"] as? String) ?? nil
        self.previouslyActiveRoute = (driverData["activeon"] as? String) ?? nil
        self.selectedRoute = (driverData["selectedroute"] as? String) ?? nil
        self.assignedRoute = (driverData["assigned"] as? String) ?? nil

        if active_since != nil {
            self.drivingBegan()
        }
        
        self.logIn()
    
    }
    
    override func drivingBegan() {
        self.active_since = self.active_since ?? Date()
        super.drivingBegan()
    }
}




class ProtoDriver {
    
    let prefs = UserDefaults.standard
    
    //LOGIN
    func logIn() {
        prefs.set(true, forKey: "loggedIn")
    }
    
    func logOut() {
        prefs.set(false, forKey: "loggedIn")
    }
    
    var isLoggedIn: Bool {
        return prefs.bool(forKey: "loggedIn")
    }
    
    var password: String {
        get {return prefs.string(forKey: "passwd") ?? ""}
        set {prefs.setValue((newValue), forKey: "passwd")}
    }
    
    
    //ID
    var driverID: Int {
        get {return prefs.integer(forKey: "driverID")}
        set {prefs.set(newValue, forKey: "driverID")}
    }
    
    //CURRENT ROUTE
    func drivingBegan() {
        prefs.set(true, forKey: "drivingBegan")
    }
    
    func drivingEnded() {
        prefs.set(false, forKey: "drivingBegan")
    }
    
    var isActive: Bool {
        return prefs.bool(forKey: "drivingBegan")
    }
        
    
}

