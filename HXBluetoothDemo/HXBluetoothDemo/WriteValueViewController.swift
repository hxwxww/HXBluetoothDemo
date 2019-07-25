//
//  WriteValueViewController.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/25.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import CoreBluetooth

/// 蓝牙m每包最大数据
let HXBLEMaxDataLength = 128

class WriteValueViewController: UITableViewController {
        
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = peripheral.peripheralName()
        nameLabel.text = characteristic.uuid.uuidString
    }

    @IBAction func sendBtnAction(_ sender: Any) {
        guard let data = textView.text.data(using: .utf8), data.count > 0 else { return }
        sendMessageData(data)
    }
    
    /// 发data
    private func sendMessageData(_ msgData: Data) {
        let datas = packageData(msgData)
        sendMessageDatas(datas)
    }
    
    /// 发送数据包
    private func sendMessageDatas(_ datas: [Data]) {
        for data in datas {
            HXLog("package data: \(HXBLEUtils.hexStringFromData(data)) length: \(data)")
            HXCentralManager.shared.writeValueForCharacteristic(peripheral: peripheral, characteristic: characteristic, value: data)
            /// 延迟
            usleep(50000)
        }
    }

    /// 封包data
    private func packageData(_ msgData: Data) -> [Data] {
        let totalLength = msgData.count
        let validLength = HXBLEMaxDataLength
        let subPackageCount = ((msgData.count - 1) / validLength) + 1
        var datas: [Data] = []
        if subPackageCount == 1 {
            datas.append(msgData)
        } else {
            for subPackageNo in 0 ..< subPackageCount {
                let from = subPackageNo * validLength
                var to = (subPackageNo + 1) * validLength
                if to >= totalLength {
                    to = totalLength
                }
                datas.append(msgData.subdata(in: from ..< to))
            }
        }
        return datas
    }
    
}
