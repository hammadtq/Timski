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
import SVProgressHUD
import Alamofire

class ChatViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    var messageArray : [MessageModel] = [MessageModel]()
    let remoteUsername : String = "tayyabejaz.id.blockstack"
    let localUsername : String = "hammadtariq.id"
    var channelFileName : String = ""
//    let remoteUsername : String = "hammadtariq.id"
//    let localUsername : String = "tayyabejaz.id.blockstack"
    var timer = Timer()
    var remoteUserLastChatStringCount = 0
    let notificationBtn = SSBadgeButton()
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        self.navigationController?.setNavigationBarBorderColor(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
        self.bottomView.layer.borderWidth = 1
        self.bottomView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        self.messageTextField.borderStyle = .none
        
        //Menu Button
        menuButton.target = self.revealViewController()
        menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        
        //Set Notification and add buttons
        notificationBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        notificationBtn.setImage(UIImage(named: "notification")?.withRenderingMode(.alwaysTemplate), for: .normal)
        notificationBtn.badgeEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 15)
        notificationBtn.tintColor = UIColor.darkGray
        
        
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(named: "add")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addButton.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        addButton.tintColor = UIColor.darkGray
        addButton.addTarget(self, action: #selector(addParticipantsOpen), for: .touchUpInside)
        let addButtonItem = UIBarButtonItem(customView: addButton)
        
        self.navigationItem.rightBarButtonItems = [addButtonItem, UIBarButtonItem(customView: notificationBtn)]
        
        //Reverse Extenstion
        //You can apply reverse effect only set delegate.
        messageTableView.re.delegate = self
        messageTableView.re.scrollViewDidReachTop = { scrollView in
            print("scrollViewDidReachTop")
        }
        messageTableView.re.scrollViewDidReachBottom = { scrollView in
            print("scrollViewDidReachBottom")
        }
        
        //Add notification listener for channel selection
        NotificationCenter.default.addObserver(self, selector: #selector(channelSelected(_:)), name:NSNotification.Name(rawValue: "channelSelected"), object: nil)
        
        //messageTableView.delegate = self
        messageTableView.re.dataSource = self
        messageTextField.delegate = self
        
        messageTableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "tableViewCell")
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        
        
        //Add observer to kill Gaia connections if user pressed Log Out button
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.stopTimerTest), name:NSNotification.Name(rawValue: "UserLoggedOut"), object: nil)
        
        configureTableView()
        
        scheduledTimerWithTimeInterval()
        
        readChannels()
    }
    
    @objc func channelSelected(_ notif: Notification) {
        updateWithChannel()
    }
    
    func readChannels(){
        SVProgressHUD.show()
        MessageService.instance.findAllChannel { (success) in
            if success {
                if MessageService.instance.channels.count > 0 {
                    MessageService.instance.selectedChannel = MessageService.instance.channels[0]
                    self.updateWithChannel()
                } else {
                    self.title = "No channels yet!"
                }
            }
        }
    }
    
    func updateWithChannel() {
        messageArray.removeAll()
        tableView.reloadData()
        let channelName = MessageService.instance.selectedChannel?.channelTitle ?? ""
        self.title = "#\(channelName)"
        self.channelFileName = (MessageService.instance.selectedChannel?.id)! + channelName
        retrieveMessages(completeFunc: readMessages)
    }

    @objc func addParticipantsOpen(){
        let addParticipants = AddParticipantsViewController()
        addParticipants.modalPresentationStyle = .custom
        present(addParticipants, animated: true, completion: nil)
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
        print("Messages are \(json)")
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

        Blockstack.shared.putFile(to: channelFileName, content: messageJSONText) { (publicURL, error) in
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
        Blockstack.shared.getFile(at: channelFileName, username: remoteUsername) { response, error in
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
        Blockstack.shared.getFile(at: channelFileName) { response, error in
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

        dispatchGroup.notify(queue: .main) {
            print("Both functions complete 👍")
            print(localJson)
            print(remoteJson)
            var combinedMessages : JSON = localJson
            if(localJson != JSON.null && remoteJson != JSON.null){
                let combinedDict = localJson.dictionaryObject?.merging(remoteJson.dictionaryObject!) { $1 }
                combinedMessages = JSON(combinedDict as Any)
            }
            completeFunc(combinedMessages)
            SVProgressHUD.dismiss()
        }
    }
    
    @objc func updateRemoteUserChat(){
        //TEMPORARY IMPLEMENTATION OF NOTIFICATION SERVICE
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.checkNotifications()
            }
        }
        print("counting..")
        Blockstack.shared.getFile(at: channelFileName, username: remoteUsername) { response, error in
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
    @objc func stopTimerTest() {
            timer.invalidate()
    }
    
    func checkNotifications(){
        // Read invitations from api
        let url = "https://api.iologics.co.uk/timski/index.php"
        let localUser = Blockstack.shared.loadUserData()?.username ?? "localUser"
        let newVar = "cryptgraphy makes the \(localUser) rock!".sha256()
        let parameters: [String: Any] = [
            "localUser" : "\(localUser)",
            "uuid" : newVar,
            "check_invitations" : 1
        ]
        Alamofire.request(url, method: .post, parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    let resultJSON : JSON = JSON(response.result.value!)
                    print("resultingJSON is")
                    print(resultJSON)
                    if resultJSON["result"] != "error"{
                        SVProgressHUD.dismiss()
                        DispatchQueue.main.async {
                            self.notificationBtn.badge = resultJSON["result"].stringValue
                        }
                        
                    }else{
                        print("error")
                    }
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
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

extension UINavigationController {
    
    func setNavigationBarBorderColor(_ color:UIColor) {
        self.navigationBar.shadowImage = color.as1ptImage()
    }
}

extension UIColor {
    
    /// Converts this `UIColor` instance to a 1x1 `UIImage` instance and returns it.
    ///
    /// - Returns: `self` as a 1x1 `UIImage`.
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}


