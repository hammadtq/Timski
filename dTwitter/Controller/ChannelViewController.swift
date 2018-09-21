//
//  ChannelViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/16/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit

class ChannelViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.revealViewController().rearViewRevealWidth = self.view.frame.size.width - 60
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func addChannelPressed(_ sender: Any) {
        let addChannel = AddChannelViewController()
        addChannel.modalPresentationStyle = .custom
        present(addChannel, animated: true, completion: nil)
    }
}
