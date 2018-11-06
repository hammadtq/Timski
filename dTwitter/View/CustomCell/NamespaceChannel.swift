//
//  NamespaceChannel.swift
//  Timski
//
//  Created by Hammad Tariq on 11/6/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit

class NamespaceCell: UITableViewCell {
    
    @IBOutlet weak var namespaceName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.layer.backgroundColor = UIColor(white: 1, alpha: 0.2).cgColor
        } else {
            self.layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    func configureCell(namespace: String) {
        let title = namespace
        namespaceName.text = "#\(title)"
    }
}
