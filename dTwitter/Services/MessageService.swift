//
//  MessageService.swift
//  Smack
//
//  Created by Jonny B on 7/18/17.
//  Copyright © 2017 Jonny B. All rights reserved.
//

import Foundation
import SwiftyJSON
import Blockstack

class MessageService {
    
    static let instance = MessageService()
    
    var channels = [Channel]()
    var unreadChannels = [String]()
    var selectedChannel : Channel?
    var selectedNamespace : String?
    
    func findAllChannel(completion: @escaping (_ Success: Bool) -> ()) {
        //Read channel data from Gaia
        Blockstack.shared.getFile(at: CHANNEL_FILE) { response, error in
            if error != nil {
                print("get file error")
                completion(false)
            } else {
                print("got channel list")
                print(response as Any)
                let convertJSON = JSON.init(parseJSON: (response as? String)!)
                if convertJSON.isEmpty {
                    //assuming the file is not there in all null cases
                    let timeStamp = NSDate().timeIntervalSince1970
                    let channelDictionary = ["\(timeStamp)" : ["name" : "general", "desc" : "General purpose channel", "participants" : [Blockstack.shared.loadUserData()?.username]]]
                    let messageJSONText = Helper.serializeJSON(messageDictionary: channelDictionary)
                    
                    Blockstack.shared.putFile(to: CHANNEL_FILE, text: messageJSONText, completion: { (publicURL, error) in
                        if error != nil {
                            print("put file error")
                        } else {
                            print("put file success \(publicURL!)")
                            var channel = Channel()
                            channel.namespace = Blockstack.shared.loadUserData()?.username
                            channel.channelTitle = "general"
                            channel.channelDescription = "General purpose channel"
                            channel.id = "\(timeStamp)"
                            channel.participants = JSON([Blockstack.shared.loadUserData()?.username])
                            self.channels.append(channel)
                            DispatchQueue.main.async{
                                completion(true)
                            }
                        }
                    })
                    
                }else{
                    self.channels.removeAll()
                    let sortedResults = convertJSON.sorted { $0 < $1 }
                    for item in sortedResults {
                        var channel = Channel()
                        if(item.0 != "foreignChannels"){
                            channel.namespace = Blockstack.shared.loadUserData()?.username
                            channel.channelTitle = item.1["name"].stringValue
                            channel.channelDescription = item.1["desc"].stringValue
                            channel.id = item.0
                            channel.participants = item.1["participants"]
                            self.channels.append(channel)
                        }else{
                            for item in item.1{
                                channel.namespace = item.1["channelOwner"].stringValue
                                channel.channelTitle = item.1["channelTitle"].stringValue
                                channel.channelDescription = ""
                                channel.id = item.0
                                channel.participants = ""
                                self.channels.append(channel)
                            }
                        }
                        
                    }
                    DispatchQueue.main.async{
                        completion(true)
                    }
                }
            }
        }

    }
    
    func getForeignChannelParticipants(completion: @escaping (_ Success: Bool) -> ()){
        
        Blockstack.shared.getFile(at: CHANNEL_FILE, username: (MessageService.instance.selectedChannel?.namespace)!) { response, error in
            if error != nil {
                //print("get file error")
                completion(false)
            } else {
                //print("got channel list")
                //print(response as Any)
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject
                if (channelDictionary![(MessageService.instance.selectedChannel?.id)!] != nil){
                    var concernedChannel = channelDictionary![(MessageService.instance.selectedChannel?.id)!] as! [String:Any]
                    let participants = concernedChannel["participants"] as! [String]
                    MessageService.instance.selectedChannel?.participants = JSON(participants)
                    DispatchQueue.main.async{
                        completion(true)
                    }
                }else{
                    print ("error in fetching remote participants")
                }
            }
        }
        
    }
    
    func getSetSavedNamespaceChannel(namespace : String, channel : Channel, write : Bool, completion: @escaping (_ Success: Bool) -> ()){
        let defaults = UserDefaults.standard
        if(defaults.object(forKey:"selectedNamespace") == nil || defaults.object(forKey:"selectedChannelDictionar") == nil || write == true){
            print("writing user defaults")
            defaults.set(namespace, forKey: "selectedNamespace")
            print(channel.participants)
            var channelParticipants = JSON(channel.participants).arrayObject as Any
            print("channel participants are")
            print(channelParticipants)
            if (channel.participants == ""){
                channelParticipants = ""
            }
            
            print(channelParticipants)
            let channelDict = ["id" : channel.id, "title" : channel.channelTitle, "description" : channel.channelDescription, "namespace" : channel.namespace, "participants": channelParticipants] as [String : Any]
            
            defaults.set(channelDict, forKey: "selectedChannelDictionar")
            MessageService.instance.selectedNamespace = namespace
            MessageService.instance.selectedChannel = channel
            completion(true)
        }else{
            print("user defaults exist")
            MessageService.instance.selectedNamespace = defaults.object(forKey:"selectedNamespace") as? String
            
            let channelDict = defaults.object(forKey: "selectedChannelDictionar") as? [String: Any] ?? [String: Any]()
            
            var channel = Channel()
            channel.id = channelDict["id"] as! String
            channel.channelDescription = channelDict["description"] as! String
            channel.channelTitle = channelDict["title"] as! String
            channel.namespace = channelDict["namespace"] as! String
            channel.participants = JSON(channelDict["participants"] as Any)
            
            MessageService.instance.selectedChannel = channel
            completion(true)
        }
    }
    
}
