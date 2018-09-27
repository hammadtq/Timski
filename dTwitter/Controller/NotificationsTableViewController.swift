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

class NotificationsTableViewController: UITableViewController {

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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
