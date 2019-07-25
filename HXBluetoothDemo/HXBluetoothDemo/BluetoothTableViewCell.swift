//
//  BluetoothTableViewCell.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var connectBtn: UIButton!
    
    var connectBtnCallback: ((PeripheralModel) -> ())?
    var peripheralModel: PeripheralModel?
    
    func updateUI(with peripheralModel: PeripheralModel) {
        let name = peripheralModel.peripheral.peripheralName(peripheralModel.advertisementData)
        let identifier = peripheralModel.peripheral.identifier.uuidString
        nameLabel.text = "\(name)   \(peripheralModel.RSSI ?? -999)"
        idLabel.text = identifier
        var btnTitle: String = ""
        switch peripheralModel.peripheral.state {
        case .connected:
            btnTitle = "Disconnect"
            connectBtn.isEnabled = true
        case .connecting:
            btnTitle = "Connecting"
            connectBtn.isEnabled = false
        case .disconnected:
            btnTitle = "Connect"
            connectBtn.isEnabled = true
        case .disconnecting:
            btnTitle = "Disconnecting"
            connectBtn.isEnabled = false
        @unknown default:
            fatalError("Peripheral state is error")
        }
        connectBtn.setTitle(btnTitle, for: .normal)
        self.peripheralModel = peripheralModel
    }
    
    @IBAction func connectBtnAction(_ sender: Any) {
        guard let peripheralModel = peripheralModel else { return }
        connectBtnCallback?(peripheralModel)
    }
    
}
