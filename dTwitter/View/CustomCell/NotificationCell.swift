//
//  NotificationCell.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/27/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import SwipeCellKit

class NotificationCell: SwipeTableViewCell {

    @IBOutlet weak var notificationText: UILabel!
    //@IBOutlet weak var notificationTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
