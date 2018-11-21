//
//  LetterImageGenerator.swift
//  ImageFromTextTutorial
//
//  Created by Matthew Howes Singleton on 7/30/17.
//  Copyright © 2017 Matthew Howes Singleton. All rights reserved.
//

import UIKit

class LetterImageGenerator: NSObject {
    class func imageWith(name: String?, imageBackgroundColor: String?) -> UIImage? {
    let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    let nameLabel = UILabel(frame: frame)
    nameLabel.textAlignment = .center
    nameLabel.textColor = .white
    nameLabel.font = UIFont.boldSystemFont(ofSize: 40)
    if(imageBackgroundColor == "local"){
            nameLabel.backgroundColor = UIColor(red:0.00, green:0.72, blue:0.58, alpha:1.0)
    }else{
            nameLabel.backgroundColor = UIColor(red:1.00, green:0.46, blue:0.46, alpha:1.0)
    }
    var initials = ""
    if let initialsArray = name?.components(separatedBy: " ") {
      if let firstWord = initialsArray.first {
        if let firstLetter = firstWord.first {
          initials += String(firstLetter).capitalized
        }
      }
      if initialsArray.count > 1, let lastWord = initialsArray.last {
        if let lastLetter = lastWord.first {
          initials += String(lastLetter).capitalized
        }
      }
    } else {
      return nil
    }
    nameLabel.text = initials
    UIGraphicsBeginImageContext(frame.size)
    if let currentContext = UIGraphicsGetCurrentContext() {
      nameLabel.layer.render(in: currentContext)
      let nameImage = UIGraphicsGetImageFromCurrentImageContext()
      return nameImage
    }
    return nil
  }
}

