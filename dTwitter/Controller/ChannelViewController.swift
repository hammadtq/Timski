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
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileName: UIButton!
    var channelArr = [Channel]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.revealViewController().rearViewRevealWidth = self.view.frame.size.width - 60
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2.0
        profileImage.layer.masksToBounds = true
        
        let userFullName = Blockstack.shared.loadUserData()?.profile?.name
        profileName.setTitle(userFullName, for: .normal)
        profileImage.image = LetterImageGenerator.imageWith(name: userFullName, imageBackgroundColor: "local")

        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(ChannelViewController.reloadData), name:NSNotification.Name(rawValue: "channelDataUpdated"), object: nil)
    }
    @IBAction func namespacePressed(_ sender: Any) {
        //performSegue(withIdentifier: "sw_rear_namespaces", sender: self)
        let replacement = self.storyboard?.instantiateViewController(withIdentifier: "namespacesVCID")
        self.revealViewController().setRear(replacement, animated: true)
    }
    
    @objc func reloadData(){
        //filtering the channels that are only available in current user namespace
        channelArr = MessageService.instance.channels.filter {
            $0.namespace ==  MessageService.instance.selectedNamespace
        }
        tableView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func profileNamePressed(_ sender: Any) {
        let profileView = UserProfileViewController()
        profileView.modalPresentationStyle = .custom
        present(profileView, animated: true, completion: nil)
    }
    
    @IBAction func addChannelPressed(_ sender: Any) {
        let addChannel = AddChannelViewController()
        addChannel.modalPresentationStyle = .custom
        present(addChannel, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCell {
            let channel = channelArr[indexPath.row]
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
        return channelArr.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = channelArr[indexPath.row]
        MessageService.instance.selectedChannel = channel
        
//        if MessageService.instance.unreadChannels.count > 0 {
//            MessageService.instance.unreadChannels = MessageService.instance.unreadChannels.filter{$0 != channel.id}
//        }
        let index = IndexPath(row: indexPath.row, section: 0)
        tableView.reloadRows(at: [index], with: .none)
        tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        
        NotificationCenter.default.post(name: Notification.Name("channelSelected"), object: nil)
        self.revealViewController().revealToggle(animated: true)
    }
    
}
