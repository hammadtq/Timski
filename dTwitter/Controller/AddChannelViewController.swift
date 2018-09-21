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
        Blockstack.shared.getFile(at: "channelFile") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get file success")
                print(response as Any)
                let json = JSON.init(parseJSON: (response as? String)!)
                var channelDictionary = json.dictionaryObject
                if channelDictionary == nil{
                    channelDictionary = ["name" :  channelName, "desc" : channelDesc]
                    
                }else{
                    channelDictionary?.updateValue(channelName, forKey: "name")
                }
                
                let channelJSONText = Helper.serializeJSON(messageDictionary: channelDictionary!)
                
                Blockstack.shared.putFile(to: "dStackFile", content: channelJSONText) { (publicURL, error) in
                    if error != nil {
                        print("put file error")
                    } else {
                        print("put file success \(publicURL!)")
                        DispatchQueue.main.async{
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
