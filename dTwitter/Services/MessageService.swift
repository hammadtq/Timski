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
    var selectedChannel : Channel?
    var channel = Channel()
    func findAllChannel(completion: @escaping (_ Success: Bool) -> ()) {
        //Read channel data from Gaia
        Blockstack.shared.getFile(at: "channelFile") { response, error in
            if error != nil {
                print("get file error")
                completion(false)
            } else {
                print("get file success")
                print(response as Any)
                let convertJSON = JSON.init(parseJSON: (response as? String)!)
                if convertJSON.isEmpty {
                    //assuming the file is not there in all null cases
                    let channelDictionary = ["name" : "general", "desc" : "General purpose channel"]
                    let messageJSONText = Helper.serializeJSON(messageDictionary: channelDictionary)
                    Blockstack.shared.putFile(to: "channelFile", content: messageJSONText, encrypt: false) { (publicURL, error) in
                        if error != nil {
                            print("put file error")
                        } else {
                            print("put file success \(publicURL!)")
                            self.channel.channelTitle = "general"
                            self.channels.append(self.channel)
                            DispatchQueue.main.async{
                                completion(true)
                            }
                        }
                    }
                    
                }else{
                    for item in convertJSON {
                        print(item.1)
                        self.channel.channelTitle = item.1.stringValue
                        self.channels.append(self.channel)
                    }
                    DispatchQueue.main.async{
                        completion(true)
                    }
                }
            }
        }

    }
    
}
