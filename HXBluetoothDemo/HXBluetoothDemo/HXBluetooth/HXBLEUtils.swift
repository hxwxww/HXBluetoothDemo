//
//  HXBLEUtils.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/24.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

extension CBPeripheral {
    
    /// 获取设备名称
    ///
    /// - Parameter advertisementData: 广播包数据
    /// - Returns: 设备名称
    func peripheralName(_ advertisementData: [String: Any]? = nil) -> String {
        return advertisementData?[CBAdvertisementDataLocalNameKey] as? String ?? name ?? "Unknown Name"
    }
    
}

class HXBLEUtils {
    
    /// hex dump
    ///
    /// - Parameter data: 数据
    /// - Returns: hexString
    static func hexStringFromData(_ data: Data?) -> String {
        guard let data = data, data.count > 0 else { return "(null)" }
        let bytes = [UInt8](data)
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02X ", byte)
        }
        return hexString
    }
    
    /// UInt16转2bytes
    ///
    /// - Parameter uint16: uint16数字
    /// - Returns: bytes数组
    static func uint16ToTwoBytes(_ uint16: UInt16) -> [UInt8] {
        return [
            UInt8(truncatingIfNeeded: uint16),
            UInt8(truncatingIfNeeded: uint16 >> 8)
        ]
    }
    
    /// UInt32转4bytes
    ///
    /// - Parameter uint32: uint32数字
    /// - Returns: bytes数组
    static func uint32ToFourBytes(_ uint32: UInt32) -> [UInt8] {
        return [
            UInt8(truncatingIfNeeded: uint32),
            UInt8(truncatingIfNeeded: uint32 >> 8),
            UInt8(truncatingIfNeeded: uint32 >> 16),
            UInt8(truncatingIfNeeded: uint32 >> 24)
        ]
    }
    
    /// UInt64转8bytes
    ///
    /// - Parameter uint64: uint64数字
    /// - Returns: bytes数组
    static func uint64ToEightBytes(_ uint64: UInt64) -> [UInt8] {
        return [
            UInt8(truncatingIfNeeded: uint64),
            UInt8(truncatingIfNeeded: uint64 >> 8),
            UInt8(truncatingIfNeeded: uint64 >> 16),
            UInt8(truncatingIfNeeded: uint64 >> 24),
            UInt8(truncatingIfNeeded: uint64 >> 32),
            UInt8(truncatingIfNeeded: uint64 >> 40),
            UInt8(truncatingIfNeeded: uint64 >> 48),
            UInt8(truncatingIfNeeded: uint64 >> 56)
        ]
    }
    
}

