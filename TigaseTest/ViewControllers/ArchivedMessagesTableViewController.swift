//
//  ArchivedMessagesTableViewController.swift
//  TigaseTest
//
//  Created by Abid Rahman on 9/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit
import TigaseSwift

class ArchivedMessagesTableViewController: UITableViewController {
    private var archivedMessages: [MessageArchiveManagementModule.ArchivedMessageReceivedEvent]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.archivedMessages = [MessageArchiveManagementModule.ArchivedMessageReceivedEvent]()
        self.tableView.reloadData()

        XMPPClientService.shared.fetchChatArchives { (archivedMessages) in
            self.archivedMessages = archivedMessages
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.archivedMessages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArchivesMessageTableViewCell") as! ArchivesMessageTableViewCell
        cell.populateData(message: self.archivedMessages[indexPath.row])
        return cell
    }
}
