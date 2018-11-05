//
//  NamespacesViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 11/3/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack

class NamespacesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileName: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2.0
        profileImage.layer.masksToBounds = true
        
        let userFullName = Blockstack.shared.loadUserData()?.profile?.name
        profileName.setTitle(userFullName, for: .normal)
        profileImage.image = LetterImageGenerator.imageWith(name: userFullName, imageBackgroundColor: "local")
    }

//    @IBAction func channelsButtonPressed(_ sender: Any) {
//        let replacement = self.storyboard?.instantiateViewController(withIdentifier: "channelsVCID")
//        self.revealViewController().setRear(replacement, animated: true)
//    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "namespaceCell", for: indexPath) as? ChannelCell {
            let channel = MessageService.instance.channels[indexPath.row]
            cell.configureCell(channel: channel)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
