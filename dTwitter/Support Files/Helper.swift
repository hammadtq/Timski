//
//  Helper.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/21/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

//struct for checking internect connectivity using Alamofire
struct Connectivity {
    static let sharedInstance = NetworkReachabilityManager()!
    static var isConnectedToInternet:Bool {
        return self.sharedInstance.isReachable
    }
}

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
    
    static func addUserJSONDataToUserDefaults(userData: JSON) {
        guard let jsonString = userData.rawString() else { return }
        UserDefaults.standard.set(jsonString, forKey: "user")
    }
    
    static func getCachedUserJSONData() -> JSON? {
        let jsonString = UserDefaults.standard.string(forKey: "user") ?? ""
        guard let jsonData = jsonString.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSON(data: jsonData)
    }
}
