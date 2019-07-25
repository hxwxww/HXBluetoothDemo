//
//  HXCentralManager.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import CoreBluetooth

class HXCentralManager: NSObject {
    
    // MARK: -  Callbacks
    
    /// 蓝牙状态更新的回调
    var didUpdateStateClosure: HXDidUpdateStateClosure?
    
    /// 设备状态更新的回调
    var didUpdatePeripheralStateClosure: HXDidUpdatePeripheralStateClosure?
    
    /// 扫描到设备的回调
    var didDiscoverPeripheralClosure: HXDidDiscoverPeripheralClosure?
    
    /// 筛选扫描到的设备的回调
    var filterDiscoveredPeripheralClosure: HXFilterDiscoveredPeripheralClosure?
    
    /// 筛选自动连接的设备的回调
    var filterAutoconnectPeripheralClosure: HXFilterAutoconnectPeripheralClosure?
    
    /// 连接上设备的回调
    var didConnectPeripheralClosure: HXDidConnectPeripheralClosure?
    
    /// 断开设备的回调
    var didDisconnectPeripheralClosure: HXDidDisconnectPeripheralClosure?
    
    /// 连接设备失败的回调
    var didFailToConnectPeripheralClosure: HXDidFailToConnectPeripheralClosure?
    
    /// 蓝牙发现设备服务的回调
    var didDiscoverServicesClosure: HXDidDiscoverServicesClosure?
    
    /// 蓝牙发现特征的回调
    var didDiscoverCharacteristicsClosure: HXDidDiscoverCharacteristicsClosure?
    
    /// 蓝牙读取特征的值的回调
    var didUpdateCharacteristicValueClosure: HXDidUpdateCharacteristicValueClosure?
    
    /// 蓝牙写入特征的值的回调
    var didWriteCharacteristicValueClosure: HXDidWriteCharacteristicValueClosure?
    
    /// 蓝牙发现特征描述符的回调
    var didDiscoverDescriptorsClosure: HXDidDiscoverDescriptorsClosure?
    
    /// 蓝牙读取特征描述符的值的回调
    var didUpdateDescriptorValueClosure: HXDidUpdateDescriptorValueClosure?
    
    /// 蓝牙写入特征描述符的值的回调
    var didWriteDescriptorValueClosure: HXDidWriteDescriptorValueClosure?
    
    // MARK: -  Public Properties
    
    /// 已扫描到的设备
    private (set) var discoveredPeripherals: [CBPeripheral] = []
    
    /// 可重连的设备
    private (set) var reconnectPeripherals: [CBPeripheral] = []
    
    /// 已连接的设备
    private (set) var connectedPeripherals: [CBPeripheral] = []
    
    /// 选项设置
    var bleOptions: HXBLEOptions = HXBLEOptions.defaultOptions()
    
    /// 是否需要扫描特征描述符，默认为false
    var shouldDiscoverDescriptors: Bool = false
    
    // MARK: -  Private Properties
    
    /// 中心设备控制器
    private var centralManager: CBCentralManager!
    
    /// 状态监听者列表
    private var stateObservers: [CBPeripheral: NSKeyValueObservation] = [:]
    
    /// 中心设备打开次数
    private var poweredOnTimes: Int = 0
    
    /// 连接定时器
    private var connectTimer: Timer?
    
    /// 自动重连定时器
    private var reconnectTimer: Timer?
    
    // MARK: -  初始化
    static let shared = HXCentralManager()
    private override init() {
        super.init()
        var options: [String: Any] = [CBCentralManagerOptionShowPowerAlertKey: true]
        if let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String],
            backgroundModes.contains("bluetooth-central") {
            /// 后台模式
            options[CBCentralManagerOptionRestoreIdentifierKey] = kRestoreIdentifier
        }
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
    }
    
}

// MARK: -  Public Methods
extension HXCentralManager {
    
    /// 开始扫描设备
    func startScan() {
        /// 检查蓝牙是否开启
        checkCentralStatePoweredOn { (isPoweredOn) in
            if isPoweredOn {
                self.centralManager.scanForPeripherals(withServices: self.bleOptions.scanForPeripheralsServiceUUIDs, options: self.bleOptions.scanForPeripheralsOptions)
            }
        }
    }
    
    /// 停止扫描设备
    func stopScan() {
        centralManager.stopScan()
    }

    /// 连接设备
    ///
    /// - Parameter peripheral: 需要连接的设备
    func connectPeripheral(_ peripheral: CBPeripheral) {
        /// 连接设备
        centralManager.connect(peripheral, options: bleOptions.connectPeripheralsOptions)
    }
    
    /// 断开连接设备
    ///
    /// - Parameter peripheral: 需要断开连接的设备
    func disconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral.state == .connecting || peripheral.state == .connected {
            /// 取消特征的通知
            if let services = peripheral.services {
                for service in services {
                    if let characteristics = service.characteristics {
                        for characteristic in characteristics {
                            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                                peripheral.setNotifyValue(false, for: characteristic)
                            }
                        }
                    }
                }
            }
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    /// 断开所有已连接的设备
    func disconnectAllPeripherals() {
        for peripheral in connectedPeripherals {
            disconnectPeripheral(peripheral)
        }
    }
    
    /// 添加设备到自动重连列表中
    ///
    /// - Parameter peripheral: 需要自动连接的设备
    func addToReconnectPeripherals(_ peripheral: CBPeripheral) {
        if !reconnectPeripherals.contains(peripheral) {
            reconnectPeripherals.append(peripheral)
        }
    }
    
    /// 从自动重连列表中删除设备
    ///
    /// - Parameter peripheral: 需要删除的设备
    func removeFromReconnectPeripherals(_ peripheral: CBPeripheral) {
        if let index = reconnectPeripherals.firstIndex(of: peripheral) {
            reconnectPeripherals.remove(at: index)
        }
    }
    
    /// 从自动重连列表中删除所有设备
    func removeAllReconnectPeripherals() {
        reconnectPeripherals.removeAll()
    }

}

// MARK: -  Private Methods
extension HXCentralManager {
    
    /// 检查蓝牙是否开启
    ///
    /// - Parameter completion: 检查完成的回调
    private func checkCentralStatePoweredOn(_ completion: @escaping (Bool) -> ()) {
        if centralManager.state == .poweredOn {
            poweredOnTimes = 0
            DispatchQueue.main.async {
                completion(true)
            }
            return
        }
        poweredOnTimes += 1
        if poweredOnTimes >= kPoweredOnMaxTimes {
            HXLog("Fail to check central state for \(poweredOnTimes) times")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        HXLog("Check central state at \(poweredOnTimes) times")
        DispatchQueue.global().asyncAfter(deadline: .now() + kPoweredOnDuration) {
            self.checkCentralStatePoweredOn(completion)
        }
    }
    
    /// 开启连接超时定时器
    private func startConnectTimer(peripheral: CBPeripheral) {
        stopConnectTimer()
        connectTimer = Timer.scheduledTimer(timeInterval: kConnectTimeOutDuration, target: self, selector: #selector(connectTimeOutAction(_:)), userInfo: ["peripheral": peripheral], repeats: false)
    }
    
    /// 停止连接超时定时器
    private func stopConnectTimer() {
        connectTimer?.invalidate()
        connectTimer = nil
    }
    
    /// 连接超时处理
    @objc private func connectTimeOutAction(_ timer: Timer) {
        /// 取出设备
        guard let userInfo = timer.userInfo as? [String: Any],
            let peripheral = userInfo["peripheral"] as? CBPeripheral else {
                return
        }
        HXLog("\(peripheral.peripheralName()) connect time out")
        /// 取消连接
        disconnectPeripheral(peripheral)
    }
    
    /// 开启自动重连定时器
    private func startReconnectTimer() {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(timeInterval: kReconnectPeripheralDuration, target: self, selector: #selector(startReconnectPeripherals), userInfo: nil, repeats: false)
    }
    
    /// 停止自动重连定时器
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    /// 开始自动重连
    @objc private func startReconnectPeripherals() {
        /// 没有连接其他设备时，重连所有可自动重连设备
        if self.connectedPeripherals.count == 0 {
            for reconnectPeripheral in self.reconnectPeripherals {
                self.connectPeripheral(reconnectPeripheral)
            }
        }
    }
    
    /// 取消其他正在连接的设备，当前设备例外
    ///
    /// - Parameter exceptPeripheral: 例外的设备
    private func cancelConnectPeripherals(exceptPeripheral: CBPeripheral) {
        for peripheral in discoveredPeripherals {
            if peripheral != exceptPeripheral {
                disconnectPeripheral(peripheral)
            }
        }
    }
    
    /// 添加到已扫描设备列表之中
    ///
    /// - Parameter peripheral: 已扫描到的设备
    private func addToDiscoveredPeripherals(_ peripheral: CBPeripheral) {
        if !discoveredPeripherals.contains(peripheral) {
            HXLog("Did discover new peripheral: \(peripheral.peripheralName())")
            /// 加入列表
            discoveredPeripherals.append(peripheral)
            /// 注册状态监听者
            let stateObserver = peripheral.observe(\.state, options: [.new, .old]) { [weak self] (_ , changed) in
                guard let `self` = self else { return }
                self.didUpdatePeripheralStateClosure?(peripheral, nil)
            }
            /// 加入监听者列表
            stateObservers[peripheral] = stateObserver
        }
    }
    
    /// 删除所有已发现设备
    private func removeAllDiscoveredPeripherals() {
        discoveredPeripherals.removeAll()
        stateObservers.removeAll()
    }
    
    /// 添加到已连接设备列表之中
    ///
    /// - Parameter peripheral: 已连接的设备
    private func addToConnectedPeripherals(_ peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) {
            connectedPeripherals.append(peripheral)
        }
    }
    
    /// 从已连接设备列表之中删除
    ///
    /// - Parameter peripheral: 要删除的设备
    private func removeFromConnectedPeripherals(_ peripheral: CBPeripheral) {
        if let index = connectedPeripherals.firstIndex(of: peripheral) {
            connectedPeripherals.remove(at: index)
        }
    }
    
    /// 开始恢复设备状态
    ///
    /// - Parameter restoredPeriperals: 要恢复的设备列表
    private func startRestoredPeriperals(_ restoredPeriperals: [CBPeripheral]) {
        for restoredPeriperal in restoredPeriperals {
            HXLog("restoredPeriperal: \(restoredPeriperal)")
            /// 回调
            didDiscoverPeripheralClosure?(centralManager, restoredPeriperal, nil, nil)
            addToDiscoveredPeripherals(restoredPeriperal)
            switch restoredPeriperal.state {
            case .connecting:
                /// 重新连接
                disconnectPeripheral(restoredPeriperal)
                connectPeripheral(restoredPeriperal)
            case .connected:
                /// 回调
                didConnectPeripheralClosure?(centralManager, restoredPeriperal)
                /// 重新搜索服务
                restoredPeriperal.delegate = self
                restoredPeriperal.discoverServices(bleOptions.discoverServiceUUIDs)
                /// 重新读取RSSI
                restoredPeriperal.readRSSI()
            default:
                break
            }
        }
    }
    
    /// 向设备特征写数据
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - characteristic: 特征
    ///   - value: 数据
    func writeValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic, value: Data) {
        if characteristic.properties.contains(.writeWithoutResponse) {
            /// 无响应
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
            HXLog("\(characteristic.uuid.uuidString) did write characteristic value: \(HXBLEUtils.hexStringFromData(value)) without response")
        } else if characteristic.properties.contains(.write) {
            /// 有回复
            peripheral.writeValue(value, for: characteristic, type: .withResponse)
        } else {
            /// 不能写
            HXLog("\(characteristic.uuid.uuidString) can not write value")
        }
    }
    
    /// 向设备特征读数据
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - characteristic: 特征
    func readValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.readValue(for: characteristic)
    }
    
    /// 向设备特征描述符写数据
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - descriptor: 特征描述符
    ///   - value: 数据
    func writeValueForDescriptor(peripheral: CBPeripheral, descriptor: CBDescriptor, value: Data) {
        peripheral.writeValue(value, for: descriptor)
    }
    
    /// 向设备特征描述符读数据
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - characteristic: 特征描述符
    func readValueForDescriptor(peripheral: CBPeripheral, descriptor: CBDescriptor) {
        peripheral.readValue(for: descriptor)
    }
    
}

// MARK: -  CBCentralManagerDelegate
extension HXCentralManager: CBCentralManagerDelegate {
    
    /// 蓝牙状态更新时回调此方法
    ///
    /// - Parameter central: centralManager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .unknown:
            HXLog("Central state is unknown")
        case .resetting:
            HXLog("Central state is resetting")
        case .unsupported:
            HXLog("Central state is unsupported")
        case .unauthorized:
            HXLog("Central state is unauthorized")
        case .poweredOff:
            HXLog("Central state is poweredOff")
        case .poweredOn:
            HXLog("Central state is poweredOn")
        @unknown default:
            fatalError("Central state is error")
        }
        didUpdateStateClosure?(central)
    }
    
    /// 恢复状态时回调此方法
    ///
    /// - Parameters:
    ///   - central: centralManager
    ///   - dict: 要恢复状态的设备、服务字典
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        guard let restoredPeriperals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
            restoredPeriperals.count > 0 else { return }
        /// 检查蓝牙是否开启
        checkCentralStatePoweredOn { (isPoweredOn) in
            if isPoweredOn {
                self.startRestoredPeriperals(restoredPeriperals)
            }
        }
    }
    
    /// 蓝牙扫描到设备之后回调此方法
    ///
    /// - Parameters:
    ///   - central: centralManager
    ///   - peripheral: 扫描到的设备
    ///   - advertisementData: 广播数据
    ///   - RSSI: 信号强度（为负数，值越大信号越好）
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        /// 筛选扫描到的设备
        if filterDiscoveredPeripheralClosure?(peripheral, advertisementData, RSSI) ?? true {
            /// 回调扫描到的设备
            didDiscoverPeripheralClosure?(central, peripheral, advertisementData, RSSI)
            /// 保存到已扫描列表中
            addToDiscoveredPeripherals(peripheral)
        }
        /// 筛选自动连接的设备
        if filterAutoconnectPeripheralClosure?(peripheral, advertisementData, RSSI) ?? false {
            connectPeripheral(peripheral)
            /// 开启连接定时器
            startConnectTimer(peripheral: peripheral)
        }
    }
    
    /// 蓝牙连接设备之后回调此方法
    ///
    /// - Parameters:
    ///   - central: centralManager
    ///   - peripheral: 连接的设备
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        HXLog("Did connect peripheral: \(peripheral.peripheralName())")
        /// 停止定时器
        stopConnectTimer()
        /// 取消其他正在连接的设备，保证同一时间只与一个设备连接
        cancelConnectPeripherals(exceptPeripheral: peripheral)
        /// 保存当前连接设备
        addToConnectedPeripherals(peripheral)
        /// 回调
        didConnectPeripheralClosure?(central, peripheral)
        /// 设置代理
        peripheral.delegate = self
        /// 扫描服务
        peripheral.discoverServices(bleOptions.discoverServiceUUIDs)
    }
    
    /// 蓝牙断开设备之后回调此方法
    ///
    /// - Parameters:
    ///   - central: centralManager
    ///   - peripheral: 断开的设备
    ///   - error: 错误
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        HXLog("Did disconnect peripheral: \(peripheral.peripheralName())")
        /// 删除已连接设备
        removeFromConnectedPeripherals(peripheral)
        /// 回调
        didDisconnectPeripheralClosure?(central, peripheral, error)
        /// 开启自动重连定时器
        startReconnectTimer()
    }
    
    /// 蓝牙连接设备失败之后回调此方法
    ///
    /// - Parameters:
    ///   - central: centralManager
    ///   - peripheral: 连接失败的设备
    ///   - error: 错误
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        HXLog("Did did fail to connect peripheral: \(peripheral.peripheralName()) error: \(error?.localizedDescription ?? "(null)")")
        /// 回调
        didFailToConnectPeripheralClosure?(central, peripheral, error)
    }
    
}

// MARK: -  CBPeripheralDelegate
extension HXCentralManager: CBPeripheralDelegate {
    
    /// 发现设备服务之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 当前设备
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        /// 回调
        didDiscoverServicesClosure?(peripheral, error)
        /// 扫描特征
        if let services = peripheral.services {
            for service in services {
                HXLog("\(peripheral.peripheralName()) discover service: \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(bleOptions.discoverCharacteristicUUIDs, for: service)
            }
        }
    }
    
    /// 发现服务的特征之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 当前设备
    ///   - service: 当前服务
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        /// 回调
        didDiscoverCharacteristicsClosure?(peripheral, service, error)
        /// 扫描特征描述
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                HXLog("\(service.uuid.uuidString) did discover characteristic: \(characteristic.uuid.uuidString)")
                /// 开启特征值通知
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                /// 读取特征值
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
                if shouldDiscoverDescriptors {
                    peripheral.discoverDescriptors(for: characteristic)
                }
            }
        }
    }
    
    /// 读取到特征的值后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 当前设备
    ///   - characteristic: 当前特征
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        HXLog("\(characteristic.uuid.uuidString) did update characteristic value: \(HXBLEUtils.hexStringFromData(characteristic.value))")
        /// 回调
        didUpdateCharacteristicValueClosure?(peripheral, characteristic, error)
    }
    
    /// 蓝牙向设备特征发数据之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 当前设备
    ///   - characteristic: 当前特征
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        HXLog("\(characteristic.uuid.uuidString) did write characteristic value with response)")
        /// 回调
        didWriteCharacteristicValueClosure?(peripheral, characteristic, error)
    }
    
    /// 发现特征描述符之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - characteristic: 特征
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        /// 回调
        didDiscoverDescriptorsClosure?(peripheral, characteristic, error)
        /// 扫描特征描述
        if let descriptors = characteristic.descriptors {
            for descriptor in descriptors {
                HXLog("\(characteristic.uuid.uuidString) did discover descriptor: \(descriptor.uuid.uuidString)")
                 /// 读取特征描述符的值
                peripheral.readValue(for: descriptor)
            }
        }
    }
    
    /// 读取特征描述符的值之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - descriptor: 描述符
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        HXLog("\(descriptor.uuid.uuidString) did update descriptor value: \(String(describing: descriptor.value))")
        /// 回调
        didUpdateDescriptorValueClosure?(peripheral, descriptor, error)
    }
    
    /// 蓝牙向设备特征描述符发数据之后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - descriptor: 描述符
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        HXLog("\(descriptor.uuid.uuidString) did write descriptor value with response)")
        /// 回调
        didWriteDescriptorValueClosure?(peripheral, descriptor, error)
    }
    
    /// 设备更改名称后回调此方法
    ///
    /// - Parameter peripheral: 设置
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        HXLog("\(peripheral.identifier.uuidString) did update name with \(peripheral.peripheralName())")
        /// 回调
        didUpdatePeripheralStateClosure?(peripheral, nil)
    }
    
    /// 设备读取RSSI后回调此方法
    ///
    /// - Parameters:
    ///   - peripheral: 设备
    ///   - RSSI: 信号强度
    ///   - error: 错误
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        HXLog("peripheral: \(peripheral.peripheralName()) did read RSSI: \(RSSI)")
        /// 回调
        didUpdatePeripheralStateClosure?(peripheral, RSSI)
    }
    
}
