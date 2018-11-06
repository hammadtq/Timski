//
//  Channel.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/23/18.
//  Copyright © 2017 Hammad Tariq. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Channel : Decodable {
    var namespace: String!
    var channelTitle: String!
    var channelDescription: String!
    var id: String!
    var participants : JSON!
}
