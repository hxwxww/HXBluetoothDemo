//
//  BluetoothViewController.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/22.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    /// 设备数据集合
    private var peripheralModels: [PeripheralModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCentralManager()
    }
    
    private func setupCentralManager() {
        let centralManager = HXCentralManager.shared
        centralManager.filterDiscoveredPeripheralClosure = { (peripheral, advertisementData, RSSI) in
            return peripheral.name != nil && peripheral.name!.count > 0
        }
        centralManager.didDiscoverPeripheralClosure = { [weak self] (central, peripheral, advertisementData, RSSI) in
            guard let `self` = self else { return }
            self.insertCell(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
        }
        centralManager.didUpdatePeripheralStateClosure = { [weak self] (peripheral, RSSI) in
            guard let `self` = self else { return }
            self.insertCell(peripheral: peripheral, advertisementData: nil, RSSI: RSSI)
        }
        centralManager.didConnectPeripheralClosure = { (central, peripheral) in
            /// 只将当前连接的设备加入重连列表中
            HXCentralManager.shared.removeAllReconnectPeripherals()
            HXCentralManager.shared.addToReconnectPeripherals(peripheral)
        }
        centralManager.startScan()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pushToPeripheralVC" {
            let peripheralVC = segue.destination as! PeripheralViewController
            peripheralVC.peripheral = sender as? CBPeripheral
        }
    }

}

// MARK: -  Private Methods
extension BluetoothViewController {
    
    private func insertCell(peripheral: CBPeripheral, advertisementData: [String: Any]?, RSSI: NSNumber?) {
        var oldIndex: Int?
        for (index, peripheralModel) in peripheralModels.enumerated() {
            if peripheralModel.peripheral == peripheral {
                oldIndex = index
                break
            }
        }
        if let oldIndex = oldIndex {
            let oldPerpheralModel = peripheralModels[oldIndex]
            let perpheralModel = PeripheralModel(peripheral: peripheral, advertisementData: advertisementData ?? oldPerpheralModel.advertisementData, RSSI: RSSI ?? oldPerpheralModel.RSSI)
            peripheralModels.replaceSubrange(oldIndex ..< oldIndex + 1, with: [perpheralModel])
            guard let cell = tableView.cellForRow(at: IndexPath(row: oldIndex, section: 0)) as? BluetoothTableViewCell else { return }
            cell.updateUI(with: perpheralModel)
        } else {
            peripheralModels.append(PeripheralModel(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI))
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: peripheralModels.count - 1, section: 0)], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    private func connectOrDisconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral.state == .disconnected {
            HXCentralManager.shared.connectPeripheral(peripheral)
        } else if peripheral.state == .connected {
            HXCentralManager.shared.disconnectPeripheral(peripheral)
        }
    }
    
}

// MARK: -  UITableViewDataSource, UITableViewDelegate
extension BluetoothViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.hx_dequeueReusableCell(indexPath: indexPath) as BluetoothTableViewCell
        let peripheralModel = peripheralModels[indexPath.row]
        cell.updateUI(with: peripheralModel)
        cell.connectBtnCallback = { [weak self] (peripheralModel) in
            guard let `self` = self else { return }
            self.connectOrDisconnectPeripheral(peripheralModel.peripheral)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripheralModels[indexPath.row].peripheral
        performSegue(withIdentifier: "pushToPeripheralVC", sender: peripheral)
    }
    
}
