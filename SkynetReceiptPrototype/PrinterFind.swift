//
//  PrinterFind.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 10/12/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation
import UIKit
import ExternalAccessory



func sendZplOverBluetooth() {
    //Find the Zebra Bluetooth Accessory
    var serialNumber: String = ""
    let sam = EAAccessoryManager.shared()
    let connAccs: [EAAccessory] = sam.connectedAccessories
    for accessory in connAccs {
        if accessory.protocolStrings.index(of: "com.zebra.rawport") != NSNotFound {
            serialNumber = accessory.serialNumber
            print(serialNumber)
            break
            //Note: This will find the first printer connected! If you have multiple Zebra printers connected, you should display a list to the user and have him select the one they wish to use
        }
    }
    
    // Instantiate connection to Zebra Bluetooth accessory
    let thePrinterConn: ZebraPrinterConnection = MfiBtPrinterConnection.init(serialNumber: serialNumber)
    
    // Open the connection - physical connection is established here.
    var success: Bool = thePrinterConn.open()
    print(success)

    // This example prints "This is a ZPL test." near the top of the label.
    let zplString: String = "^XA^FO20,20^A0N,25,25^FDThis is a ZPL test.^FS^XZ"
    let zplData: Data = zplString.data(using: String.Encoding.utf8)!
    print(zplData)
//    let error: NSError?

    // Send the data to printer as a byte array.
    success = success && thePrinterConn.write(zplData, error: nil) != -1
    if !success {
//        let errorAlert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        print("ERROR")
    }
   
    // Close the connection to release resources.
    thePrinterConn.close()
    

}



