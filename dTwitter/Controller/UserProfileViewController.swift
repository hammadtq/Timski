//
//  UserProfileViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/23/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack

class UserProfileViewController : UIViewController {
    
    // Outlets
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImg.layer.cornerRadius = profileImg.bounds.width / 2.0
        profileImg.layer.masksToBounds = true
        setupView()
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        Blockstack.shared.signUserOut()
        NotificationCenter.default.post(name: Notification.Name("UserLoggedOut"), object: nil)
       // dismiss(animated: true, completion: nil)
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeModalPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupView() {
        let userFullName = Blockstack.shared.loadUserData()?.profile?.name ?? "Nameless User"
        userName.text = userFullName
        userEmail.text = Blockstack.shared.loadUserData()?.profile?.description
        profileImg.image = LetterImageGenerator.imageWith(name: userFullName, imageBackgroundColor: "local")
        //profileImg.backgroundColor = UserDataService.instance.returnUIColor(components: UserDataService.instance.avatarColor)
        
        let closeTouch = UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.closeTap(_:)))
        bgView.addGestureRecognizer(closeTouch)
    }
    
    @objc func closeTap(_ recognizer: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
}
