//
//  PeripheralModel.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

struct PeripheralModel {
    var peripheral: CBPeripheral
    var advertisementData: [String: Any]?
    var RSSI: NSNumber?
}
