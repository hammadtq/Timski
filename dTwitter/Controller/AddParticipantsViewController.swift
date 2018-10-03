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
import SwiftyJSON
import Alamofire

class AddParticipantsViewController: UIViewController {

    
    @IBOutlet weak var blockstackUserID: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blockstackUserID.becomeFirstResponder()
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
                let url = "https://api.iologics.co.uk/timski/index.php"
                let channelID = MessageService.instance.selectedChannel?.id
                let channelTitle = MessageService.instance.selectedChannel?.channelTitle
                let localUser = Blockstack.shared.loadUserData()?.username
                let newVar = "cryptgraphy makes the \(localUser!) rock!".sha256()
                let parameters: [String: Any] = [
                    "localUser" : "\( localUser ?? "localUser")",
                    "remoteUser" : userID,
                    "channelID" : channelID!,
                    "channelTitle" : channelTitle!,
                    "uuid" : newVar,
                    "add_participant" : 1
                    ]
                Alamofire.request(url, method: .post, parameters: parameters)
                    .responseJSON { response in
                        if response.result.isSuccess {
                            let resultJSON : JSON = JSON(response.result.value!)
                            print(resultJSON)
                            if resultJSON["result"] == "success"{
                                SVProgressHUD.dismiss()
                                DispatchQueue.main.async {
                                    let participantName = profile?.name
                                    let selectedChannel = MessageService.instance.selectedChannel?.channelTitle
                                    let alert = UIAlertController(title: "Invitation Success", message: "\(participantName ?? "Nameless User") has been invited to join #\(selectedChannel ?? "")", preferredStyle: UIAlertControllerStyle.alert)
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
                                
                            }else if resultJSON["result"] == "duplicate"{
                                SVProgressHUD.dismiss()
                                DispatchQueue.main.async {
                                    let participantName = profile?.name
                                    let selectedChannel = MessageService.instance.selectedChannel?.channelTitle
                                    let alert = UIAlertController(title: "Duplicate Invitation", message: "\(participantName ?? "Nameless User") has already been requested to join #\(selectedChannel ?? "")", preferredStyle: UIAlertControllerStyle.alert)
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
                                
                            }else{
                                print("error")
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Error", message: "Could not add user to the channel!", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                    self.present(alert, animated: true)
                                }
                            }
                            
                        } else {
                            print("Error: \(String(describing: response.result.error))")
                        }
                }
//                DispatchQueue.main.async {
//                    //var participants = MessageService.instance.selectedChannel?.participants.arrayValue as Array!
//                    //print(participants)
//                    //participants?.append(JSON(userID))
//                    //print(participants)
//                    SVProgressHUD.dismiss()
//                    let participantName = profile?.name
//                    let alert = UIAlertController(title: "Confirmation", message: "\(participantName ?? "Nameless User") has been added to the channel", preferredStyle: UIAlertControllerStyle.alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { action in
//                        switch action.style{
//                        case .default:
//                            self.dismiss(animated: true, completion: nil)
//
//                        case .cancel:
//                            print("cancel")
//
//                        case .destructive:
//                            print("destructive")
//
//
//                        }}))
//                    self.present(alert, animated: true, completion: nil)
//                }
            }
        }
    }
    

}
