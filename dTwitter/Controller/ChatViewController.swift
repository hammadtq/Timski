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
import ReverseExtension

class ChatViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    var messageArray : [Message] = [Message]()
   
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //You can apply reverse effect only set delegate.
        messageTableView.re.delegate = self
        messageTableView.re.scrollViewDidReachTop = { scrollView in
            print("scrollViewDidReachTop")
        }
        messageTableView.re.scrollViewDidReachBottom = { scrollView in
            print("scrollViewDidReachBottom")
        }
        
        //messageTableView.delegate = self
        messageTableView.re.dataSource = self
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
    
    func updateRowsInTable(){
        self.configureTableView()
        
        messageTableView.beginUpdates()
        messageTableView.re.insertRows(at: [IndexPath.init(row: messageArray.count - 1, section: 0)], with: .automatic)
        messageTableView.endUpdates()
    }
    
    //MARK:- Blockstack Functions
    func readMessages(json : JSON){
        //print("Messages are \(json)")
        let sortedResults = json.sorted { $0 < $1 }
        print(sortedResults)
        messageArray.removeAll()
        for message in sortedResults{
            print (message.1["messagebody"])
            let text = "\(message.1["messagebody"])"
            let sender = "Hammad"
            
            let message = Message()
            
            message.messageBody = text
            message.sender = sender
            
            messageArray.append(message)
            updateRowsInTable()
        }
        
    }
    
    func combineMessages(json : JSON){
        //print("Messages are \(json)")
        
        
        var messageDictionary = json.dictionaryObject
        let timeInterval = NSDate().timeIntervalSince1970
        let newItem = ["messagebody": messageTextField.text!]
        if messageDictionary == nil{
            messageDictionary = ["\(timeInterval)" :  newItem]
            
        }else{
            messageDictionary?.updateValue(newItem, forKey: "\(timeInterval)")
        }
        
        var messageJSONText : String = ""
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: messageDictionary!,
            options: []) {
            messageJSONText = String(data: theJSONData,
                                     encoding: .ascii)!
            //print("JSON string = \(messageJSONText)")
        }

        Blockstack.shared.putFile(to: "dStackFile", content: messageJSONText) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")
                DispatchQueue.main.async{
                    
                    let message = Message()
                    let sender = "Hammad"
                    message.messageBody = self.messageTextField.text!
                    message.sender = sender
                    self.messageArray.append(message)
                    self.updateRowsInTable()
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
                    //print(json)
                    completeFunc(json)
                }
            }
            
        }
    }
    
}
extension ViewController: UITableViewDelegate {
    //ReverseExtension also supports handling UITableViewDelegate.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView.contentOffset.y =", scrollView.contentOffset.y)
    }
}

