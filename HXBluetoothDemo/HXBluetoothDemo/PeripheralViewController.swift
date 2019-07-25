//
//  PeripheralViewController.swift
//  HXBluetoothDemo
//
//  Created by HongXiangWen on 2019/7/24.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController {

    var peripheral: CBPeripheral!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var connectItem: UIBarButtonItem!
    @IBOutlet weak var stateLabel: UILabel!
    private var serviceModels: [ServiceModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCentralManager()
        updatePeripheralUI()
    }
    
    private func setupCentralManager() {
        let centralManager = HXCentralManager.shared
        centralManager.didUpdatePeripheralStateClosure = { [weak self] (peripheral, RSSI) in
            guard let `self` = self, self.peripheral == peripheral else { return }
            self.updatePeripheralUI()
        }
        centralManager.didDiscoverServicesClosure = { [weak self] (peripheral, error) in
            guard let `self` = self else { return }
            guard let services = peripheral.services else { return }
            for service in services {
                self.insertSection(service: service)
            }
        }
        centralManager.didDiscoverCharacteristicsClosure = { [weak self] (peripheral, service, error) in
            guard let `self` = self else { return }
            self.insertRows(service: service)
        }
        centralManager.didUpdateCharacteristicValueClosure = { [weak self] (peripheral, characteristic, error) in
            guard let `self` = self else { return }
            self.updateCell(characteristic: characteristic)
        }
        centralManager.connectPeripheral(peripheral)
    }
    
    private func updatePeripheralUI() {
        self.title = peripheral.peripheralName()
        switch peripheral.state {
        case .connected:
            stateLabel.text = "Connected"
            stateLabel.textColor = .green
            connectItem.title = "Disconnect"
        case .connecting:
            stateLabel.text = "Connecting"
            stateLabel.textColor = .lightGray
            connectItem.title = "Disconnect"
        case .disconnected:
            stateLabel.text = "Disconnected"
            stateLabel.textColor = .red
            connectItem.title = "Connect"
            serviceModels.removeAll()
            tableView.reloadData()
        case .disconnecting:
            stateLabel.text = "Disconnecting"
            stateLabel.textColor = .lightGray
            connectItem.title = "Connect"
            serviceModels.removeAll()
            tableView.reloadData()
        @unknown default:
            fatalError("Peripheral state is error")
        }
    }
    
    @IBAction func connectItemAction(_ sender: Any) {
        switch peripheral.state {
        case .connected, .connecting:
            HXCentralManager.shared.disconnectPeripheral(peripheral)
            serviceModels.removeAll()
            tableView.reloadData()
        case .disconnected, .disconnecting:
            HXCentralManager.shared.connectPeripheral(peripheral)
        @unknown default:
            fatalError("Peripheral state is error")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pushToWritreValueVC" {
            let writeVC = segue.destination as! WriteValueViewController
            writeVC.peripheral = peripheral
            writeVC.characteristic = sender as? CBCharacteristic
        }
    }
    
}

// MARK: -  Private Methods
extension PeripheralViewController {
    
    private func insertSection(service: CBService) {
        let serviceModel = ServiceModel(service: service, characteristics: [])
        serviceModels.append(serviceModel)
        let sections = IndexSet(integer: serviceModels.count - 1)
        tableView.beginUpdates()
        tableView.insertSections(sections, with: .automatic)
        tableView.endUpdates()
    }
    
    private func insertRows(service: CBService) {
        guard let characteristics = service.characteristics else { return }
        var section: Int = -1
        for (index, serviceModel) in serviceModels.enumerated() {
            if service == serviceModel.service {
                section = index
                break
            }
        }
        if section == -1 {
            return
        }
        var serviceModel = serviceModels[section]
        serviceModel.characteristics = characteristics
        serviceModels.replaceSubrange(section ..< section + 1, with: [serviceModel])
        var indexPaths: [IndexPath] = []
        for row in 0 ..< characteristics.count {
            let indexPath = IndexPath(row: row, section: section)
            indexPaths.append(indexPath)
        }
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
    }
    
    private func updateCell(characteristic: CBCharacteristic) {
        var indexPath: IndexPath?
        for (section, serviceModel) in serviceModels.enumerated() {
            for (row, c) in serviceModel.characteristics.enumerated() {
                if c == characteristic {
                    indexPath = IndexPath(row: row, section: section)
                    break
                }
            }
        }
        guard let idxPath = indexPath else { return }
        serviceModels[idxPath.section].characteristics.replaceSubrange( idxPath.row ..< idxPath.row + 1, with: [characteristic])
        tableView.beginUpdates()
        tableView.reloadRows(at: [idxPath], with: .automatic)
        tableView.endUpdates()
    }
    
    private func readValue(characteristic: CBCharacteristic) {
        HXCentralManager.shared.readValueForCharacteristic(peripheral: peripheral, characteristic: characteristic)
    }
    
    private func writeValue(characteristic: CBCharacteristic) {
        performSegue(withIdentifier: "pushToWritreValueVC", sender: characteristic)
    }
    
}

// MARK: -  UITableViewDataSource, UITableViewDelegate
extension PeripheralViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return serviceModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceModels[section].characteristics.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        headerView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: view.bounds.width - 30, height: 60))
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        label.text = serviceModels[section].service.description
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.hx_dequeueReusableCell(indexPath: indexPath) as PeripheralTableViewCell
        let characteristic = serviceModels[indexPath.section].characteristics[indexPath.row]
        cell.updateUI(characteristic: characteristic)
        cell.readValueCallback = { [weak self] in
            guard let `self` = self else { return }
            self.readValue(characteristic: characteristic)
        }
        cell.writeValueCallback = { [weak self] in
            guard let `self` = self else { return }
            self.writeValue(characteristic: characteristic)
        }
        return cell
    }

}
