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
    
    func findAllChannel(completion: @escaping (_ Success: Bool) -> ()) {
        //Read channel data from Gaia
        Blockstack.shared.getFile(at: CHANNEL_FILE) { response, error in
            if error != nil {
                print("get file error")
                completion(false)
            } else {
                print("get file success")
                print(response as Any)
                let convertJSON = JSON.init(parseJSON: (response as? String)!)
                if convertJSON.isEmpty {
                    //assuming the file is not there in all null cases
                    let timeStamp = NSDate().timeIntervalSince1970
                    let channelDictionary = ["\(timeStamp)" : ["name" : "general", "desc" : "General purpose channel", "participants" : [Blockstack.shared.loadUserData()?.username]]]
                    let messageJSONText = Helper.serializeJSON(messageDictionary: channelDictionary)
                    Blockstack.shared.putFile(to: CHANNEL_FILE, content: messageJSONText, encrypt: false) { (publicURL, error) in
                        if error != nil {
                            print("put file error")
                        } else {
                            print("put file success \(publicURL!)")
                            var channel = Channel()
                            channel.channelTitle = "general"
                            channel.channelDescription = "General purpose channel"
                            channel.id = "\(timeStamp)"
                            self.channels.append(channel)
                            DispatchQueue.main.async{
                                completion(true)
                            }
                        }
                    }
                    
                }else{
                    self.channels.removeAll()
                    let sortedResults = convertJSON.sorted { $0 < $1 }
                    for item in sortedResults {
                        print(item.1)
                        var channel = Channel()
                        channel.channelTitle = item.1["name"].stringValue
                        channel.channelDescription = item.1["desc"].stringValue
                        channel.id = item.0
                        self.channels.append(channel)
                    }
                    DispatchQueue.main.async{
                        completion(true)
                    }
                }
            }
        }

    }
    
}
