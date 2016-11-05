//
//  PrinterManager.swift
//  Skynet Mk4a
//
//  Created by Chris Spradling on 10/13/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation
import ExternalAccessory



@objc enum printerErrorCode: Int {
    case kErrorWrongLanguage
    case kErrorNoPrinter
    case kErrorInvalidInput
    case kErrorPrintingError
}


@objc enum printerStatusCode: Int {
    case kStatusConnecting
    case kStatusSendingData
    case kStatusDisconnecting
}


@objc protocol PrinterManagerDelegate: class {
    @objc func printerStatusChanged(status: printerStatusCode)
    @objc func printerFailedWithCode(error: printerErrorCode)
    @objc func printerFinishedPrinting()
}


class PrinterManager: NSObject {
    
    let delegate: PrinterManagerDelegate
    var commands: String = ""
    
    init(delegate: PrinterManagerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    
    func print() {
        Thread.detachNewThreadSelector(#selector(startPrinter), toTarget: self, with: nil)
    }
    
    
    func startPrinter() {
        
        var couldPrint: Bool = false
        
        DispatchQueue.main.async {
            self.delegate.printerStatusChanged(status: .kStatusConnecting)
        }
        
        let manager = EAAccessoryManager.shared()
        let printer = manager.connectedAccessories.first
        
        guard
            let serial = printer?.serialNumber,
            let connection = MfiBtPrinterConnection.init(serialNumber: serial),
            connection.open(),
            let zPrinter: ZebraPrinter = try? ZebraPrinterFactory.getInstance(connection)
        else {
            DispatchQueue.main.async {
                self.delegate.printerFailedWithCode(error: .kErrorNoPrinter)
            }
            return
        }
        
        
        defer {
                        
            self.delegate.printerStatusChanged(status: .kStatusDisconnecting)
            Thread.sleep(forTimeInterval: 2.0)
            
            connection.close()
            if couldPrint {
                
                DispatchQueue.main.async {
                    self.delegate.printerFinishedPrinting()
                }
            }
        }
        
        DispatchQueue.main.async {
            if zPrinter.getControlLanguage() != PRINTER_LANGUAGE_ZPL {
                self.delegate.printerFailedWithCode(error: .kErrorWrongLanguage)
                return
            } else {
                self.delegate.printerStatusChanged(status: .kStatusSendingData)
            }
        }
    
        do {
            try zPrinter.getToolsUtil().sendCommand(self.commands)
            couldPrint = true
            
        } catch let error {
            DispatchQueue.main.async {
                self.delegate.printerFailedWithCode(error: .kErrorPrintingError)
                debugPrint("Printer Error: \(error.localizedDescription)")
                return
            }
        }
        

    }
}
