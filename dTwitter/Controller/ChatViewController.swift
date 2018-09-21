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
    
    var messageArray : [MessageModel] = [MessageModel]()
    let remoteUsername : String = "tayyabejaz.id.blockstack"
    let localUsername : String = "hammadtariq.id"
//    let remoteUsername : String = "hammadtariq.id"
//    let localUsername : String = "tayyabejaz.id.blockstack"
    var timer = Timer()
    var remoteUserLastChatStringCount = 0
   
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Menu Button
        menuButton.target = self.revealViewController()
        menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        
        //Reverse Extenstion
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
        
        messageTableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "tableViewCell")
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        
        configureTableView()
        
        retrieveMessages(completeFunc: readMessages)
        
        scheduledTimerWithTimeInterval()
    }
    
    
    @IBAction func logOutPressed(_ sender: Any) {
        stopTimerTest()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as! TableViewCell
        
        cell.messageLabel.text = messageArray[indexPath.row].message
        cell.timeLabel.text = messageArray[indexPath.row].time
        cell.iconImageView.image = messageArray[indexPath.row].imageName
        //cell.senderUsername.text = messageArray[indexPath.row].sender
        
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
        //print(sortedResults)
        messageArray.removeAll()
        for message in sortedResults{
            //print (message.1["messagebody"])
            let text = "\(message.1["messagebody"])"
            let username = "\(message.1["username"])"
            let time = Double(message.0)
            
            let dateFormatter = DateFormatter()
            let date = Date(timeIntervalSince1970: time!)
            dateFormatter.dateFormat = "HH:mm"
            let strDate = dateFormatter.string(from: date)
            
            let messageModel = MessageModel()
            
            messageModel.message = text
            messageModel.time = strDate
            if(username == localUsername){
                messageModel.imageName = LetterImageGenerator.imageWith(name: username, imageBackgroundColor: "local")
            }else{
                messageModel.imageName = LetterImageGenerator.imageWith(name: username, imageBackgroundColor: "remote")
            }
            
            messageArray.append(messageModel)
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
        
        let messageJSONText = Helper.serializeJSON(messageDictionary: messageDictionary!)

        Blockstack.shared.putFile(to: "dStackFile", content: messageJSONText) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")
                DispatchQueue.main.async{
                    
                    let message = MessageModel()
                    message.message = self.messageTextField.text!
                    message.imageName = LetterImageGenerator.imageWith(name: self.localUsername, imageBackgroundColor: "local")
                    let dateFormatter = DateFormatter()
                    let date = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
                    dateFormatter.dateFormat = "HH:mm"
                    let strDate = dateFormatter.string(from: date)
                    message.time = strDate
                    self.messageArray.append(message)
                    self.updateRowsInTable()
                    self.messageTextField.text = ""
                }
            }
        }
        
        
    }
    
    func retrieveMessages(completeFunc: @escaping (JSON) -> Void){
        
        var localJson : JSON = ""
        var remoteJson : JSON = ""
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        // Read data from Gaia
        Blockstack.shared.getFile(at: "dStackFile", username: remoteUsername) { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get remote file success")
                //print(response as Any)
                let fetchResponse = (response as? String)!
                self.remoteUserLastChatStringCount = fetchResponse.count
                remoteJson = JSON.init(parseJSON: fetchResponse)
                for (key, var item) in remoteJson {
                    item["username"] = JSON(self.remoteUsername)
                    remoteJson[key] = item
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        // Read data from Gaia'
        Blockstack.shared.getFile(at: "dStackFile") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get local file success")
                //print(response as Any)
                localJson = JSON.init(parseJSON: (response as? String)!)
                for (key, var item) in localJson {
                    item["username"] = JSON(self.localUsername)
                    localJson[key] = item
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        dispatchGroup.notify(queue: .main) {
            print("Both functions complete 👍")
            print(localJson)
            print(remoteJson)
            var combinedMessages : JSON = ""
            if(localJson != JSON.null && remoteJson != JSON.null){
                let combinedDict = localJson.dictionaryObject?.merging(remoteJson.dictionaryObject!) { $1 }
                combinedMessages = JSON(combinedDict as Any)
            }
            completeFunc(combinedMessages)
        }
    }
    
    @objc func updateRemoteUserChat(){
        print("counting..")
        Blockstack.shared.getFile(at: "dStackFile", username: remoteUsername) { response, error in
            if error != nil {
                print("get file error")
            } else {
                //print("get remote file success")
                //print(response as Any)
                let fetchResponse = (response as? String)!
                

                DispatchQueue.main.async {
                    if fetchResponse.count > self.remoteUserLastChatStringCount{
                        let parseJson = JSON.init(parseJSON: (response as? String)!)
                        let sortedResults = parseJson.sorted { $0 < $1 }
                       
                        let message = MessageModel()
                        message.message = "\(sortedResults.last?.1["messagebody"] ?? "New Message")"
                        message.imageName = LetterImageGenerator.imageWith(name: self.remoteUsername, imageBackgroundColor: "remote")
                        let dateFormatter = DateFormatter()
                        let date = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
                        dateFormatter.dateFormat = "HH:mm"
                        let strDate = dateFormatter.string(from: date)
                        message.time = strDate
                        self.messageArray.append(message)
                        self.remoteUserLastChatStringCount = fetchResponse.count
                        self.updateRowsInTable()
                        }
                }

            }
        }
    }
    
    //Mark-: Timer Functions for Polling
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateRemoteUserChat), userInfo: nil, repeats: true)
    }
    func stopTimerTest() {
            timer.invalidate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
extension ViewController: UITableViewDelegate {
    //ReverseExtension also supports handling UITableViewDelegate.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView.contentOffset.y =", scrollView.contentOffset.y)
    }
}


