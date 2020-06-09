//
//  FirstViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 8/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    @IBOutlet weak var agentIdTextField: UITextField!
    @IBOutlet weak var connectionStatusLabel: UILabel!

    private var connectionStartTime: Date!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.agentIdTextField.text = "30958"

        NotificationCenter.default.addObserver(self, selector: #selector(self.didConnect), name: 
            NSNotification.Name("didConnect"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDisconnect), name:
        NSNotification.Name("didDisconnect"), object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }

    @IBAction func connectPressed(_ sender: Any) {
        XMPPClientService.shared.setAgentId(agentId: self.agentIdTextField.text ?? "")
        self.connectionStatusLabel.text = "Connecting..."
        XMPPClientService.shared.connect()
    }
    
    @IBAction func disconnectPressed(_ sender: Any) {
        XMPPClientService.shared.disconnect()
    }

    @objc private func didConnect() {
        self.connectionStartTime = Date()
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = "Connected"
        }
    }

    @objc private func didDisconnect() {
        let connectionEndTime = Date()

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .full
        let duration = formatter.string(from: self.connectionStartTime, to: connectionEndTime)!
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = "Disconnected. Connection duration " + duration
        }
    }

    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
