//
//  GroupChatViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 28/8/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit
import TigaseSwift

class GroupChatViewController: UIViewController {

    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var inviteeJIDTextField: UITextField!
    
    @IBOutlet weak var roomIdTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!

    @IBOutlet weak var newMessageReceivedLabel: UILabel!

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var receiverLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.inviteeJIDTextField.text = "38096@ssfapp.innovatorslab.net,38100@ssfapp.innovatorslab.net"
        self.roomIdTextField.text = "0c6e6168-194e-482d-ac5a-8d1b9824d5c6"

        self.newMessageReceivedLabel.alpha = 0

        NotificationCenter.default.addObserver(self, selector: #selector(self.newGroupMessageReceived(_:)), name: NSNotification.Name("newGroupMessageReceived"), object: nil)
    }

    @objc private func newGroupMessageReceived(_ notification: Notification) {
        if let receivedMessage = notification.userInfo?["receivedMessage"] as? MucModule.MessageReceivedEvent {
            DispatchQueue.main.async { [weak self] in
                self?.newMessageReceivedLabel.alpha = 1.0
                UIView.animate(withDuration: 3) { [weak self] in
                    self?.newMessageReceivedLabel.alpha = 0.0
                }

                self?.senderLabel.text = "Sender Nickname: " + (receivedMessage.nickname ?? "")
                self?.receiverLabel.text = "Room JID: " + (receivedMessage.room.roomJid.stringValue)
                self?.bodyLabel.text = "Body: " + (receivedMessage.message.body ?? "")
            }
        }
    }

    @IBAction func createRoomPressed(_ sender: Any) {
        XMPPClientService.shared.createNewChatRoom(roomName: self.roomNameTextField.text!, inviteeJIDs: self.inviteeJIDTextField.text!.components(separatedBy: ","))
    }

    @IBAction func joinRoomPressed(_ sender: Any) {
        XMPPClientService.shared.joinRoom(roomId: self.roomIdTextField.text!)
    }

    @IBAction func sendMessagePressed(_ sender: Any) {
        XMPPClientService.shared.sendMessageToLastJoinedRoom(roomId: self.roomIdTextField.text!, message: self.messageTextField.text!)
    }
}
