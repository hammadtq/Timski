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
    var namespaceArr = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2.0
        profileImage.layer.masksToBounds = true
        
        let userFullName = Blockstack.shared.loadUserData()?.profile?.name
        profileName.setTitle(userFullName, for: .normal)
        profileImage.image = LetterImageGenerator.imageWith(name: userFullName, imageBackgroundColor: "local")
        reloadData()
    }
    
    @objc func reloadData(){
        for channel in MessageService.instance.channels{
            if !namespaceArr.contains(channel.namespace){
                namespaceArr.append(channel.namespace)
            }
        }
        print(namespaceArr)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return namespaceArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "namespaceCell", for: indexPath) as? NamespaceCell {
            let namespace = namespaceArr[indexPath.row]
            cell.configureCell(namespace: namespace)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let namespace = namespaceArr[indexPath.row]
        MessageService.instance.selectedNamespace = namespace
        
        let index = IndexPath(row: indexPath.row, section: 0)
        tableView.reloadRows(at: [index], with: .none)
        tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        
        NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
    
        let replacement = self.storyboard?.instantiateViewController(withIdentifier: "channelsVCID")
        self.revealViewController().setRear(replacement, animated: true)
    }
}
