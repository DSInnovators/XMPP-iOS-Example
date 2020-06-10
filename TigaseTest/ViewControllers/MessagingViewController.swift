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

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var receiverLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.newMessageReceivedLabel.alpha = 0

        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived(_:)), name: NSNotification.Name("newMessageReceived"), object: nil)
    }

    @objc private func newMessageReceived(_ notification: Notification) {
        if let receivedMessage = notification.userInfo?["receivedMessage"] as? MessageModule.MessageReceivedEvent {
            DispatchQueue.main.async {
                self.newMessageReceivedLabel.alpha = 1.0
                UIView.animate(withDuration: 3) { [weak self] in
                    self?.newMessageReceivedLabel.alpha = 0.0
                }

                self.senderLabel.text = "Sender: " + (receivedMessage.message.from?.bareJid.stringValue ?? "")
                self.receiverLabel.text = "Receiver: " + (receivedMessage.message.to?.bareJid.stringValue ?? "")
                self.bodyLabel.text = "Body: " + (receivedMessage.message.body ?? "")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
