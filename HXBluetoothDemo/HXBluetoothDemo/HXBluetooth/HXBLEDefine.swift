//
//  HXBLEDefine.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import Foundation

// MARK: - 自定义Log
func HXLog<T>(_ message: T, filePath: String = #file, methodName: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (filePath as NSString).lastPathComponent.components(separatedBy: ".").first!
    print("==>> \(fileName).\(methodName)[\(line)]: \(message) \n")
    #endif
}

// MARK: - 常量

/// 蓝牙恢复标识符
let kRestoreIdentifier = "your restore identifier"

/// 最多等待蓝牙打开次数
let kPoweredOnMaxTimes = 5

/// 等待设备打开间隔时间
let kPoweredOnDuration = 1.0

/// 连接超时时间
let kConnectTimeOutDuration = 5.0

/// 自动重连时间
let kReconnectPeripheralDuration = 3.0
