//
//  SignatureView.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 8/11/16.
//  Copyright © 2016 LOBC. All rights reserved.
//
import UIKit
import Foundation

class SignatureView: UIViewController, YPDrawSignatureViewDelegate, PrinterManagerDelegate {
    
    let imageScaleQuality: CGFloat = 0.25
    
    var truck: RouteObject?
    var retailer: RetailerObject? { return truck?.routeSheet[0] }
    
    @IBOutlet var signatureWindow: YPDrawSignatureView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signatureWindow.delegate = self
        
        var sales = [3, 5, 7, 1, 5, 3, 2, 2, 1]
        
        self.truck = RouteObject(jsonData: fauxRetailerData as! Dictionary<String,AnyObject>)
        if let topGolf = truck?.routeSheet[0] {
            topGolf.cash = nil
            topGolf.invoice = 16000062
            topGolf.kegCredits = 2
            for brand in topGolf.onTapAtThisStop {
                brand.todaySale = sales.popLast()
                brand.todayLevel = 1
                brand.saleAttendedTo = true
                brand.levelAttendedTo = true
                brand.complete = true
            }
        }
        
        
        if let opal = truck?.routeSheet[1] {
            opal.cash = false
            opal.checkNumber = 1234
            opal.invoice = 16000064
            opal.kegCredits = 4
            for brand in opal.onTapAtThisStop {
                brand.todaySale = sales.popLast()
                brand.todayLevel = 1
                brand.saleAttendedTo = true
                brand.levelAttendedTo = true
                brand.complete = true
            }
        }

    }

    
    private var currentDateAsNumbers: String {
        let format = DateFormatter()
        format.dateFormat = "yyMMddHHmmss"
        return format.string(from: Date())
    }
    
    
    private var automaticFilename: String {
        guard let retailer = self.retailer else { return "1234556789" }
        return "\(retailer.parentTruck.driverID)-\(retailer.id)-\(currentDateAsNumbers)"
    }
    
    
    @IBAction func confirmButtonPressed(_ sender: AnyObject) {
        if let sig: UIImage = signatureWindow.getSignature() {

            retailer?.signature = sig
            retailer?.signatureFilename = automaticFilename
            
            retailer?.printReceipt(delegate: self)
        }
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        signatureWindow.clearSignature()
    }
    
    
    // Empty; need to be present for YPDrawSignature
    func finishedSignatureDrawing() {}
    func startedSignatureDrawing() {}
    
    
    
    func printerStatusChanged(status: printerStatusCode) {
        print("Status Update: \(status.rawValue)")
        // kStatusConnecting
        // kStatusSendingData
        // kStatusDisconnecting
        return
    }
    
    func printerFinishedPrinting() {
        print("Printing Complete")
        return
    }
    
    func printerFailedWithCode(error: printerErrorCode) {
        print("ERROR: \(error.rawValue)")
        // kErrorWrongLanguage
        // kErrorNoPrinter
        // kErrorInvalidInput
        // kErrorPrintingError
        return
    }
}
