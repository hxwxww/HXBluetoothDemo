//
//  HXBLECallback.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

// MARK: -  Callbacks

/// 蓝牙状态更新
typealias HXDidUpdateStateClosure = (_ central: CBCentralManager) -> ()

/// 蓝牙设备状态更新
typealias HXDidUpdatePeripheralStateClosure = (_ peripheral: CBPeripheral, _ RSSI: NSNumber?) -> ()

/// 蓝牙扫描到设备
typealias HXDidDiscoverPeripheralClosure = (_ central: CBCentralManager, _ peripheral: CBPeripheral, _ advertisementData: [String : Any]?, _ RSSI: NSNumber?) -> ()

/// 蓝牙已连接设备
typealias HXDidConnectPeripheralClosure = (_ central: CBCentralManager, _ peripheral: CBPeripheral) -> ()

/// 蓝牙已断开设备
typealias HXDidDisconnectPeripheralClosure = (_ central: CBCentralManager, _ peripheral: CBPeripheral, _ error: Error?) -> ()

/// 蓝牙连接设备失败
typealias HXDidFailToConnectPeripheralClosure = (_ central: CBCentralManager, _ peripheral: CBPeripheral, _ error: Error?) -> ()

/// 蓝牙发现设备服务
typealias HXDidDiscoverServicesClosure = (_ peripheral: CBPeripheral, _ error: Error?) -> ()

/// 蓝牙发现特征
typealias HXDidDiscoverCharacteristicsClosure = (_ peripheral: CBPeripheral, _ service: CBService, _ error: Error?) -> ()

/// 蓝牙发现特征描述符
typealias HXDidDiscoverDescriptorsClosure = (_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic, _ error: Error?) -> ()

/// 蓝牙读取特征的值
typealias HXDidUpdateCharacteristicValueClosure = (_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic, _ error: Error?) -> ()

/// 蓝牙读取特征描述符的值
typealias HXDidUpdateDescriptorValueClosure = (_ peripheral: CBPeripheral, _ descriptor: CBDescriptor, _ error: Error?) -> ()

/// 蓝牙写入特征的值
typealias HXDidWriteCharacteristicValueClosure = (_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic, _ error: Error?) -> ()

/// 蓝牙写入特征描述符的值
typealias HXDidWriteDescriptorValueClosure = (_ peripheral: CBPeripheral, _ descriptor: CBDescriptor, _ error: Error?) -> ()

// MARK: -  Filters

/// 筛选蓝牙扫描到的设备
typealias HXFilterDiscoveredPeripheralClosure = (_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ RSSI: NSNumber) -> Bool

/// 筛选自动连接的设备
typealias HXFilterAutoconnectPeripheralClosure = (_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ RSSI: NSNumber) -> Bool
