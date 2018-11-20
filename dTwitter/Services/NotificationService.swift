//
//  NotificationService.swift
//  Timski
//
//  Created by Hammad Tariq on 11/7/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import Alamofire
import SwiftyJSON
import SVProgressHUD

class NotificationService {
    
    static let instance = NotificationService()
    var notificationArray : [NotificationModel] = [NotificationModel]()
    
    //CURRENTLY THIS FUNCTION IS RUNNING ON EACH APP LOAD FROM CHATVIEWCONTROLLER
    //Retrieve accepted invitations from the centralized server and if there are any, add them to local user's channel and delete from the server
    func retrieve_accepted_notifications(){
        
        // Read accepted invitations from api
        let url = "https://api.iologics.co.uk/timski/index.php"
        let localUser = Blockstack.shared.loadUserData()?.username ?? "localUser"
        let newVar = "cryptgraphy makes the \(localUser) rock!".sha256()
        let parameters: [String: Any] = [
            "localUser" : "\(localUser)",
            "uuid" : newVar,
            "retrieve_accepted_invitations" : 1
        ]
        Alamofire.request(url, method: .post, parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    let resultJSON : JSON = JSON(response.result.value!)
                    if resultJSON["result"] != "error"{
                        DispatchQueue.main.async {
                            print("result array is")
                            let resultArray = resultJSON["result"].arrayValue
                            print(resultArray)
                            
                            for result in resultArray{
                                let notificationModel = NotificationModel()
                                notificationModel.remoteUser = result["remoteUser"].stringValue
                                notificationModel.notificationTime = result["timestamp"].stringValue
                                notificationModel.remoteChannel = result["channelID"].stringValue
                                notificationModel.remoteChannelTitle = result["channelTitle"].stringValue
                                notificationModel.notificationID = result["id"].stringValue
                                self.notificationArray.append(notificationModel)
                            }
                            self.addParticipantsToChannel()
                        }
                        
                    }else{
                        print("error")
                        //self.notificationBtn.badge = nil
                    }
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
        }
        
    }
    
    //Add accepted invitation to the user's local channel file
    //MINOR FUNCTIONALITY BUG: WHILE ADDING PARTICIPANTS, THE ACCEPTING USER NEEDS TO UPDATE THE OPEN CHANNEL's PARTICIPANTS
    //OTHERWISE HE/SHE/IT CANNOT SEE REMOTE MESSAGES UNTIL THE CHANNEL IS RELOADED
    func addParticipantsToChannel(){
        Blockstack.shared.getFile(at: CHANNEL_FILE) { response, error in
            if error != nil {
                print("get file error")
            } else {
                //print("get file success")
                //print(response as Any)
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject
                
                for notification in self.notificationArray {
                    //print(notification.remoteChannel)
                    if (channelDictionary![notification.remoteChannel] != nil){
                        var concernedChannel = channelDictionary![notification.remoteChannel] as! [String:Any]
                        var participants = concernedChannel["participants"] as! [String]
                        if (!participants.contains(notification.remoteUser)){
                            participants.append(notification.remoteUser)
                        }
                        concernedChannel["participants"] = participants
                        channelDictionary?.updateValue(concernedChannel, forKey: notification.remoteChannel)
                    }
                }
                let channelJSONText = Helper.serializeJSON(messageDictionary: channelDictionary!)

                Blockstack.shared.putFile(to: CHANNEL_FILE, content: channelJSONText) { (publicURL, error) in
                    if error != nil {
                        print("put file error")
                    } else {
                        print("put file success \(publicURL!)")
                        DispatchQueue.main.async{
                            MessageService.instance.findAllChannel(completion: { (success) in
                                NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
                                //self.dismiss(animated: true, completion: nil)
                                self.deleteAcceptedNotifications()
                            })

                        }
                    }
                }
            }
        }
    }
    
    //Delete notifications once accepted back by the original initator
    
    func deleteAcceptedNotifications(){
        let url = "https://api.iologics.co.uk/timski/index.php"
        //let url = "https://requestbin.fullcontact.com/1ispa221"
        let localUser = Blockstack.shared.loadUserData()?.username
        let newVar = "cryptgraphy makes the \(localUser!) rock!".sha256()
        var notificationIDs = [String]()
        for notification in notificationArray {
            notificationIDs.append(notification.notificationID)
        }
        
        let notificationIDsString = notificationIDs.joined(separator: ",")
        let parameters: [String: Any] = [
            "localUser" : "\( localUser ?? "localUser")",
            "notificationIDs" : notificationIDsString,
            "uuid" : newVar,
            "delete_accepted_invitations": 1
        ]
        Alamofire.request(url, method: .post, parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    let resultJSON : JSON = JSON(response.result.value!)
                    print(resultJSON)
                    if resultJSON["result"] == "success"{
                        print("deleted accepted ids")
                    }else{
                        print("error")
                    }
                }
        }
    }
}
