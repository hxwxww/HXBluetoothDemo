//
//  HXBLEOptions.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/24.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

struct HXBLEOptions {
    
    /// scanForPeripheralsWithServices:options: 的第一个参数，需要扫描的蓝牙的服务UUID数组
    var scanForPeripheralsServiceUUIDs: [CBUUID]? = nil
    
    /// scanForPeripheralsWithServices:options: 的第二个参数，扫描的选项设置
    /// CBCentralManagerScanOptionAllowDuplicatesKey: 是否忽略将同一个设备的多个发现事件被聚合成一个发现事件，默认为false
    /// CBCentralManagerScanOptionSolicitedServiceUUIDsKey: 需要指定扫描的蓝牙的服务UUID数组
    var scanForPeripheralsOptions: [String: Any]? = nil
    
    /// connectPeripheral:options: 的第二个参数，连接的选项设置
    /// CBConnectPeripheralOptionNotifyOnConnectionKey: 当应用挂起时，如果设备连接成功，是否提示用户，默认为false
    /// CBConnectPeripheralOptionNotifyOnDisconnectionKey: 当应用挂起时，如果设备断开，是否提示用户，默认为false
    /// CBConnectPeripheralOptionNotifyOnNotificationKey: 当应用挂起时，如果收到设备的通知，是否提示用户，默认为false
    var connectPeripheralsOptions: [String: Any]? = nil
    
    /// discoverServices: 的参数，需要扫描的服务UUID数组
    var discoverServiceUUIDs: [CBUUID]? = nil
    
    /// discoverCharacteristics:forService: 的第一个参数，需要扫描的特性UUID数组
    var discoverCharacteristicUUIDs: [CBUUID]? = nil
    
    // MARK: -  初始化
    
    init(scanForPeripheralsServiceUUIDs: [CBUUID]?,
         scanForPeripheralsOptions: [String: Any]?,
         connectPeripheralsOptions: [String: Any]?,
         discoverServiceUUIDs: [CBUUID]?,
         discoverCharacteristicUUIDs: [CBUUID]?) {
        self.scanForPeripheralsServiceUUIDs = scanForPeripheralsServiceUUIDs
        self.scanForPeripheralsOptions = scanForPeripheralsOptions
        self.connectPeripheralsOptions = connectPeripheralsOptions
        self.discoverServiceUUIDs = discoverServiceUUIDs
        self.discoverCharacteristicUUIDs = discoverCharacteristicUUIDs
    }
    
    /// 初始化一个默认选项
    ///
    /// - Returns: 默认选项
    static func defaultOptions() -> HXBLEOptions {
        return HXBLEOptions(scanForPeripheralsServiceUUIDs: nil, scanForPeripheralsOptions: [CBCentralManagerScanOptionAllowDuplicatesKey : true], connectPeripheralsOptions: nil, discoverServiceUUIDs: nil, discoverCharacteristicUUIDs: nil)
    }
    
}
