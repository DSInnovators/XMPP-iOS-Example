//
//  ArchivesMessageTableViewCell.swift
//  TigaseTest
//
//  Created by Abid Rahman on 9/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit
import TigaseSwift

class ArchivesMessageTableViewCell: UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var receiverLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!

    func populateData(message: MessageArchiveManagementModule.ArchivedMessageReceivedEvent) {
        self.senderLabel.text = "Sender: " + (message.message.from?.bareJid.stringValue ?? "")
        self.receiverLabel.text = "Receiver: " + (message.message.to?.bareJid.stringValue ?? "")
        self.bodyLabel.text = "Body: " + (message.message.body ?? "")

        let df = DateFormatter()
        df.dateFormat = "d MMM YYYY h:mm:ss aa"
        self.timestampLabel.text = "Timestamp: " + df.string(from: message.timestamp)
    }
}
