//
//  NotificationsTableViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/26/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwipeCellKit

class NotificationsTableViewController: UITableViewController, SwipeTableViewCellDelegate {
    @IBOutlet var noNotificationsView: UIView!
    
    var notificationArray : [NotificationModel] = [NotificationModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkNotificationsDetail()
    }
    
    func checkNotificationsDetail(){
        // Read invitations from api
        SVProgressHUD.show()
        let url = "https://api.iologics.co.uk/timski/index.php"
        let localUser = Blockstack.shared.loadUserData()?.username ?? "localUser"
        let newVar = "cryptgraphy makes the \(localUser) rock!".sha256()
        let parameters: [String: Any] = [
            "localUser" : "\(localUser)",
            "uuid" : newVar,
            "retrieve_invitations" : 1
        ]
        Alamofire.request(url, method: .post, parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    let resultJSON : JSON = JSON(response.result.value!)
                    print("resultingJSON is")
                    print(resultJSON)
                    if resultJSON["result"] != "error"{
                        SVProgressHUD.dismiss()
                        DispatchQueue.main.async {
                            
                            let resultArray = resultJSON["result"].arrayValue
                            
                            for result in resultArray{
                                let notificationModel = NotificationModel()
                                notificationModel.remoteUser = result["localUser"].stringValue
                                notificationModel.notificationTime = result["timestamp"].stringValue
                                notificationModel.remoteChannel = result["channelID"].stringValue
                                notificationModel.remoteChannelTitle = result["channelTitle"].stringValue
                                notificationModel.notificationID = result["id"].stringValue
                                self.notificationArray.append(notificationModel)
                            }
                            self.tableView.reloadData()
                        }
                        
                    }else{
                        print("error")
                        DispatchQueue.main.async {
                            SVProgressHUD.dismiss()
                            self.tableView.backgroundView = self.noNotificationsView
                        }
                    }
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
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
        return notificationArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath) as? NotificationCell {
            cell.delegate = self
            if !notificationArray.isEmpty{
                
                cell.notificationText.text = "\(notificationArray[indexPath.row].remoteUser) wants you to join #\(notificationArray[indexPath.row].remoteChannelTitle)"
                let time = Double(notificationArray[indexPath.row].notificationTime)
                let dateFormatter = DateFormatter()
                let date = Date(timeIntervalSince1970: time!)
                dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
                let strDate = dateFormatter.string(from: date)
                cell.notificationTime.text = strDate
                
            }
            return cell
        }else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let rejectAction = SwipeAction(style: .default, title: "Reject") { action, indexPath in
            // handle action by updating model with deletion
            self.rejectRequest(at: indexPath)
        }
        
        // customize the action appearance
        rejectAction.image = UIImage(named: "delete")
        
        let approveAction = SwipeAction(style: .default, title: "Approve") { action, indexPath in
            // handle action by updating model with deletion
            self.acceptRequest(at: indexPath)
        }
        approveAction.backgroundColor = UIColor.white
        approveAction.textColor = UIColor.black
        
        // customize the action appearance
        approveAction.image = UIImage(named: "checked")
        
        return [approveAction,rejectAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
    
    func acceptRequest(at indexPath: IndexPath){
        SVProgressHUD.show()
        Blockstack.shared.getFile(at: CHANNEL_FILE) { response, error in
            if error != nil {
                SVProgressHUD.dismiss()
                print("get file error")
            } else {
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject

                //check if foreignChannels object exists otherwise make one
                if var foreignChannels = channelDictionary!["foreignChannels"] as? Dictionary<String, AnyObject> {

                    //create a new channel and insert it in older foreign channles
                    let newChannel =  ["channelOwner" : self.notificationArray[indexPath.row].remoteUser, "channelTitle": self.notificationArray[indexPath.row].remoteChannelTitle]

                    foreignChannels[self.notificationArray[indexPath.row].remoteChannel] = newChannel as AnyObject
                    channelDictionary?.updateValue(foreignChannels, forKey: "foreignChannels")

                }else{
                    let newChannel =  [self.notificationArray[indexPath.row].remoteChannel : ["channelOwner" : self.notificationArray[indexPath.row].remoteUser, "channelTitle": self.notificationArray[indexPath.row].remoteChannelTitle]]
                    channelDictionary?.updateValue(newChannel, forKey: "foreignChannels")
                }

                let channelJSONText = Helper.serializeJSON(messageDictionary: channelDictionary!)

                Blockstack.shared.putFile(to: CHANNEL_FILE, content: channelJSONText) { (publicURL, error) in
                    if error != nil {
                        SVProgressHUD.dismiss()
                        print("put file error")
                    } else {
                        print("put file success \(publicURL!)")
                        DispatchQueue.main.async{
                            MessageService.instance.findAllChannel(completion: { (success) in
                                NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
                            })
                            self.updateInvitation(at: indexPath, action: "accept")
                        }
                    }
                }
            }
        }
    }
    
    func rejectRequest(at indexPath: IndexPath){
        updateInvitation(at: indexPath, action: "delete")
    }

    func updateInvitation(at indexPath: IndexPath, action: String){
        print("inside update invitation")
        let url = "https://api.iologics.co.uk/timski/index.php"
        let localUser = Blockstack.shared.loadUserData()?.username
        let newVar = "cryptgraphy makes the \(localUser!) rock!".sha256()
        let parameters: [String: Any] = [
            "localUser" : "\( localUser ?? "localUser")",
            "notificationID" : notificationArray[indexPath.row].notificationID,
            "uuid" : newVar,
            "\(action)_Invitation": 1
        ]
        Alamofire.request(url, method: .post, parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    let resultJSON : JSON = JSON(response.result.value!)
                    print(resultJSON)
                    if resultJSON["result"] == "success"{
                        SVProgressHUD.dismiss()
                        DispatchQueue.main.async {
                            self.notificationArray.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            SVProgressHUD.dismiss()
                            self.reloadData()
                        }
                    }else{
                        print("error")
                        DispatchQueue.main.async {
                            SVProgressHUD.dismiss()
                            let alert = UIAlertController(title: "Error", message: "Could not \(action) the invitation", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                }
        }
    }
    
    func reloadData(){
        if notificationArray.isEmpty{
            tableView.backgroundView = noNotificationsView
            tableView.reloadData()
        }else{
            tableView.reloadData()
        }
    }


}

