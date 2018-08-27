//
//  ChatTableViewController.swift
//  dTwitter
//
//  Created by Hammad Tariq on 8/24/18.
//  Copyright © 2018 Hammad Tariq. All rights reserved.
//

import UIKit
import Blockstack
import SwiftyJSON

class ChatViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    var messageArray : [Message] = [Message]()
   
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTextField.delegate = self
        
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        
        configureTableView()
        
        retrieveMessages(completeFunc: readMessages)
    }
    
    
    @IBAction func logOutPressed(_ sender: Any) {
        // Sign user out
        Blockstack.shared.signOut()
        let navigationController = self.presentingViewController as? UINavigationController
        
        self.dismiss(animated: true) {
            let _ = navigationController?.popToRootViewController(animated: true)
        }
    }
    
    ///////////////////////////////////////////
    
    //MARK:- TableView DataSource Methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    func configureTableView(){
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    @objc func tableViewTapped(){
        messageTextField.endEditing(true)
    }
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.constant = 308
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        UIView.animate(withDuration: 0.2) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        
        messageTextField.endEditing(true)

        retrieveMessages(completeFunc: combineMessages)
    }
    
    func readMessages(json : JSON){
        //print("Messages are \(json)")
        
        for message in json{
            print (message.1["messagebody"])
            let text = "\(message.1["messagebody"])"
            let sender = "Hammad"
            
            let message = Message()
            
            message.messageBody = text
            message.sender = sender
            
            messageArray.append(message)
            
            self.configureTableView()
            self.messageTableView.reloadData()
        }
    }
    
    func combineMessages(json : JSON){
        print("Messages are \(json)")
        
        
        let messageDictionary = json.dictionaryObject
        let timeInterval = NSDate().timeIntervalSince1970
        let newItem = ["\(timeInterval)": ["messagebody": messageTextField.text!]]
        let combinedDict = messageDictionary?.merging(newItem) { $1 }
        
        var messageJSONText : String = ""
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: combinedDict!,
            options: []) {
            messageJSONText = String(data: theJSONData,
                                     encoding: .ascii)!
            print("JSON string = \(messageJSONText)")
        }

        Blockstack.shared.putFile(to: "dStackFile", content: messageJSONText) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")
                DispatchQueue.main.async{
                    self.messageTextField.text = ""
                }
            }
        }
        
        
    }
    
    func retrieveMessages(completeFunc: @escaping (JSON) -> Void){
        // Read data from Gaia'
        Blockstack.shared.getFile(at: "dStackFile") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get file success")
                //print(response as Any)
                
                
                let json = JSON.init(parseJSON: (response as? String)!)
                DispatchQueue.main.async{
                    completeFunc(json)
                }
            }
            
        }
    }
    
}
