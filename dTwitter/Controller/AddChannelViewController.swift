//
//  AddChannelViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 9/21/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import SwiftyJSON

class AddChannelViewController: UIViewController {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var channelDesc: UITextField!
    @IBOutlet weak var bgView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    @IBAction func createChannelPressed(_ sender: Any) {
        guard let channelName = nameText.text , nameText.text != "" else { return }
        guard let channelDesc = channelDesc.text else { return }
        Blockstack.shared.getFile(at: "channelTest7") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get file success")
                print(response as Any)
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject
                let timeStamp = NSDate().timeIntervalSince1970
                let newChannel =  ["name" : channelName, "desc" : channelDesc]
                
                channelDictionary?.updateValue(newChannel, forKey: "\(timeStamp)")
                
                let channelJSONText = Helper.serializeJSON(messageDictionary: channelDictionary!)
                
                Blockstack.shared.putFile(to: "channelTest7", content: channelJSONText) { (publicURL, error) in
                    if error != nil {
                        print("put file error")
                    } else {
                        print("put file success \(publicURL!)")
                        DispatchQueue.main.async{
                            MessageService.instance.findAllChannel(completion: { (success) in
                                NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
                                 self.dismiss(animated: true, completion: nil)
                            })
                           
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func closeModalPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setUpView(){
        let closeTouch = UITapGestureRecognizer(target: self, action: #selector(AddChannelViewController.closeTap(_:)))
        bgView.addGestureRecognizer(closeTouch)
        
    }
    
    @objc func closeTap(_ recognizer : UITapGestureRecognizer){
        dismiss(animated: true, completion: nil)
    }
    
    

}
