//
//  ChannelViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/16/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack

class ChannelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.revealViewController().rearViewRevealWidth = self.view.frame.size.width - 60
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func addChannelPressed(_ sender: Any) {
        let addChannel = AddChannelViewController()
        addChannel.modalPresentationStyle = .custom
        present(addChannel, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCell {
            let channel = MessageService.instance.channels[indexPath.row]
            cell.configureCell(channel: channel)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MessageService.instance.channels.count
    }
    
    
}
