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
                                notificationModel.remoteUser = result["localUser"].stringValue
                                notificationModel.notificationTime = result["timestamp"].stringValue
                                notificationModel.remoteChannel = result["channelID"].stringValue
                                notificationModel.remoteChannelTitle = result["channelTitle"].stringValue
                                notificationModel.notificationID = result["id"].stringValue
                                self.notificationArray.append(notificationModel)
                            }
                            
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
    
    func addParticipantsToChannel(){
        Blockstack.shared.getFile(at: CHANNEL_FILE) { response, error in
            if error != nil {
                print("get file error")
            } else {
                //print("get file success")
                //print(response as Any)
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject
                var concernedChannel = channelDictionary![self.notificationArray[indexPath.row].remoteChannel]! as! [String:Any]
                var participants = concernedChannel["participants"] as! [String]
                participants.append((Blockstack.shared.loadUserData()?.username)!)
                //print(participants)
                concernedChannel["participants"] = participants
                //print(concernedChannel)
                channelDictionary?.updateValue(concernedChannel, forKey: self.notificationArray[indexPath.row].remoteChannel)
                print(channelDictionary)
                
                let channelJSONText = Helper.serializeJSON(messageDictionary: channelDictionary!)
                
                Blockstack.shared.putFile(to: CHANNEL_FILE, content: channelJSONText) { (publicURL, error) in
                    if error != nil {
                        print("put file error")
                    } else {
                        print("put file success \(publicURL!)")
                        DispatchQueue.main.async{
                            MessageService.instance.findAllChannel(completion: { (success) in
                                NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
                                self.dismiss(animated: true, completion: nil)
                            })
                            
                        }
                    }
                }
            }
        }
    }
}
