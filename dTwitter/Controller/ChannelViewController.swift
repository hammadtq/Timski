//
//  ChannelViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/16/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import SwiftyJSON

class ChannelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var channels = [Channel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        readChannels()
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
            let channel = channels[indexPath.row]
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
        return channels.count
    }
    
    
    func readChannels(){
        //Read channel data from Gaia
        Blockstack.shared.getFile(at: "channelFile") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get file success")
                print(response as Any)
                let convertJSON = JSON.init(parseJSON: (response as? String)!)
                if convertJSON.isEmpty {
                    //assuming the file is not there in all null cases
                    let channelDictionary = ["name" : "general"]
                    let messageJSONText = Helper.serializeJSON(messageDictionary: channelDictionary)
                    Blockstack.shared.putFile(to: "channelFile", content: messageJSONText, encrypt: false) { (publicURL, error) in
                        if error != nil {
                            print("put file error")
                        } else {
                            print("put file success \(publicURL!)")
                            self.readChannels()
                        }
                    }
                    
                }else{
                    print("channel file exists")
                    print(convertJSON)
                    var channel = Channel()
                    for item in convertJSON {
                        print(item.1)
                        channel.channelTitle = item.1.stringValue
                        self.channels.append(channel)
                    }
                    DispatchQueue.main.async{
                        self.reloadTableData()
                    }
                }
            }
        }
    }
    
    func reloadTableData(){
        tableView.reloadData()
    }
    
}
