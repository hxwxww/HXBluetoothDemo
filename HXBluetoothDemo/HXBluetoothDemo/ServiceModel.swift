//
//  ServiceModel.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/24.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

struct ServiceModel {
    var service: CBService
    var characteristics: [CBCharacteristic]
}
