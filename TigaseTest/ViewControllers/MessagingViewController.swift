//
//  MessagingViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 10/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit
import TigaseSwift

class MessagingViewController: UIViewController {
    @IBOutlet weak var newMessageReceivedLabel: UILabel!
    @IBOutlet weak var chatStatusLabel: UILabel!
    
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var receiverLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    @IBOutlet weak var recipientJIDTextField: UITextField!
    @IBOutlet weak var messageTextField: ChatTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.messageTextField.chatTextFieldDelegate = self

        self.newMessageReceivedLabel.alpha = 0
        self.chatStatusLabel.isHidden = true

        self.recipientJIDTextField.text = "38100@ssfapp.innovatorslab.net"

        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived(_:)), name: NSNotification.Name("newMessageReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.chatStausChanged(_:)), name: NSNotification.Name("chatStausChanged"), object: nil)
    }

    @IBAction func sendPressed(_ sender: Any) {
        XMPPClientService.shared.sendMessage(recipientJID: self.recipientJIDTextField.text!, message: self.messageTextField.text!)
        self.messageTextField.text = nil
    }

    @objc private func newMessageReceived(_ notification: Notification) {
        if let receivedMessage = notification.userInfo?["receivedMessage"] as? MessageModule.MessageReceivedEvent {
            DispatchQueue.main.async { [weak self] in
                self?.newMessageReceivedLabel.alpha = 1.0
                UIView.animate(withDuration: 3) { [weak self] in
                    self?.newMessageReceivedLabel.alpha = 0.0
                }

                self?.senderLabel.text = "Sender: " + (receivedMessage.message.from?.bareJid.stringValue ?? "")
                self?.receiverLabel.text = "Receiver: " + (receivedMessage.message.to?.bareJid.stringValue ?? "")
                self?.bodyLabel.text = "Body: " + (receivedMessage.message.body ?? "")
            }
        }
    }

    @objc private func chatStausChanged(_ notification: Notification) {
        if let chatStateMessage = notification.userInfo?["chatStateMessage"] as? MessageModule.MessageReceivedEvent {
            DispatchQueue.main.async { [weak self] in
                switch chatStateMessage.message.chatState {
                case .composing:
                    self?.chatStatusLabel.text = (chatStateMessage.message.from?.bareJid.stringValue ?? "") + " is typing..."
                    self?.chatStatusLabel.isHidden = false
                case .paused:
                    self?.chatStatusLabel.isHidden = true
                default:
                    return
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MessagingViewController: ChatTextFieldDelegate {
    func didStartTyping() {
        XMPPClientService.shared.sendChatStateNotification(recipientJID: self.recipientJIDTextField.text!, chatState: .composing)
    }

    func didEndTyping() {
        XMPPClientService.shared.sendChatStateNotification(recipientJID: self.recipientJIDTextField.text!, chatState: .paused)
    }
}
