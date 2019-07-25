//
//  PeripheralTableViewCell.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/24.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var propertiesLabel: UILabel!
    
    var readValueCallback: (() -> ())?
    var writeValueCallback: (() -> ())?

    @IBAction func readValueBtnAction(_ sender: Any) {
        readValueCallback?()
    }
    
    @IBAction func writeValueBtnAction(_ sender: Any) {
        writeValueCallback?()
    }
    
    func updateUI(characteristic: CBCharacteristic) {
        nameLabel.text = characteristic.uuid.uuidString
        valueLabel.text = HXBLEUtils.hexStringFromData(characteristic.value)
        let properties = characteristic.properties
        var pText = ""
        if properties.contains(.broadcast) {
            pText += "broadcast | "
        }
        if properties.contains(.read) {
            pText += "read | "
        }
        if properties.contains(.writeWithoutResponse) {
            pText += "writeWithoutResponse | "
        }
        if properties.contains(.write) {
            pText += "write | "
        }
        if properties.contains(.notify) {
            pText += "notify | "
        }
        if properties.contains(.indicate) {
            pText += "indicate | "
        }
        if properties.contains(.authenticatedSignedWrites) {
            pText += "authenticatedSignedWrites | "
        }
        if properties.contains(.extendedProperties) {
            pText += "extendedProperties | "
        }
        if pText.count > 0 {
            pText = String(pText.dropLast(3))
        }
        propertiesLabel.text = pText
    }
    
}
