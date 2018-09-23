//
//  AddParticipantsViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/23/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import SVProgressHUD

class AddParticipantsViewController: UIViewController {

    
    @IBOutlet weak var blockstackUserID: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addParticipantPressed(_ sender: Any) {
        guard let userID = blockstackUserID.text , blockstackUserID.text != "" else { return }
        SVProgressHUD.show()
        Blockstack.shared.lookupProfile(username: userID) { (profile, error) in
            if error != nil {
                print("get file error")
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: "Could not find a Blockstack user with given ID", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    let participantName = profile?.name
                    let alert = UIAlertController(title: "Confirmation", message: "\(participantName ?? "Nameless User") has been added to the group", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { action in
                        switch action.style{
                        case .default:
                            self.dismiss(animated: true, completion: nil)
                            
                        case .cancel:
                            print("cancel")
                            
                        case .destructive:
                            print("destructive")
                            
                            
                        }}))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    

}
