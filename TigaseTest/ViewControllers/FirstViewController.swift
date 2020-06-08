//
//  FirstViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 8/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func connectPressed(_ sender: Any) {
        XMPPClientService.shared.connect()
    }
    
    @IBAction func disconnectPressed(_ sender: Any) {
        XMPPClientService.shared.disconnect()
    }
}
