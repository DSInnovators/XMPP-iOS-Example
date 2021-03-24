//
//  GroupChatUserManagementViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 3/9/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit

class GroupChatUserManagementViewController: UIViewController {
    @IBOutlet weak var roomIdTextField: UITextField!
    @IBOutlet weak var userToAddJIDTextField: UITextField!
    @IBOutlet weak var userToRemoveJIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.roomIdTextField.text = "0c6e6168-194e-482d-ac5a-8d1b9824d5c6"

        self.userToAddJIDTextField.text = ""
        self.userToRemoveJIDTextField.text = ""
    }

    @IBAction func addToRoomPressed(_ sender: Any) {
        XMPPClientService.shared.addUserToExistingRoom(roomId: self.roomIdTextField.text!, userJID: self.userToAddJIDTextField.text!)
    }

    @IBAction func removeFromRoomPressed(_ sender: Any) {
        XMPPClientService.shared.removeUserFromExistingRoom(roomId: self.roomIdTextField.text!, userJID: self.userToRemoveJIDTextField.text!)
    }
}
