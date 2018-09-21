//
//  Helper.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/21/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import Foundation

class Helper{
    
    static func serializeJSON (messageDictionary : Dictionary<String, Any>) -> String{
        var messageJSONText : String = ""
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: messageDictionary,
            options: []) {
            
            messageJSONText = String(data: theJSONData,
                                     encoding: .utf8)!
            
            print("JSON string = \(messageJSONText)")
        }
        return messageJSONText
    }
    
}
