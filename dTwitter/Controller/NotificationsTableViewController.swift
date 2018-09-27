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
                            print(resultArray[1]["remoteUser"])
                            let notificationModel = NotificationModel()
                            for result in resultArray{
                                notificationModel.remoteUser = result["remoteUser"].stringValue
                                notificationModel.notificationTime = result["timestamp"].stringValue
                                notificationModel.remoteChannel = result["channelID"].stringValue
                                self.notificationArray.append(notificationModel)
                            }
                            self.tableView.reloadData()
                        }
                        
                    }else{
                        print("error")
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
                
                cell.notificationText.text = "\(notificationArray[indexPath.row].remoteUser) wants you to join \(notificationArray[indexPath.row].remoteChannel)"
                let time = Double(notificationArray[indexPath.row].notificationTime)
                let dateFormatter = DateFormatter()
                let date = Date(timeIntervalSince1970: time!)
                dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
                let strDate = dateFormatter.string(from: date)
                cell.notificationTime.text = strDate
                
            }else{
                cell.textLabel?.text = "You don't have any notifications"
            }
            return cell
        }else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .default, title: "Reject") { action, indexPath in
            // handle action by updating model with deletion
            //self.updateModel(at: indexPath)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete")
        
        let approveAction = SwipeAction(style: .default, title: "Approve") { action, indexPath in
            // handle action by updating model with deletion
            //self.updateModel(at: indexPath)
        }
        approveAction.backgroundColor = UIColor.white
        approveAction.textColor = UIColor.black
        
        // customize the action appearance
        approveAction.image = UIImage(named: "checked")
        
        return [approveAction,deleteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
    



}
