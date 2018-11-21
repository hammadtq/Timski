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
    let remoteUsername : String = "muneeb.id"
    let localUsername : String = (Blockstack.shared.loadUserData()?.username)!
    var channelFileName : String = ""
    var timer = Timer()
    
    var activateTimer : Bool = false
    let defaults = UserDefaults.standard
    
    var messageProgress = [Int]()
    var sentImage : UIImage = UIImage(named: "checked_simple")!
    
    var participantLastMessageStringCount = [String: Int]()
    var remoteUserLastChatStringCount = 0
    let notificationBtn = SSBadgeButton()
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        self.navigationController?.setNavigationBarBorderColor(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
        self.bottomView.layer.borderWidth = 1
        self.bottomView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        self.messageTextField.borderStyle = .none
        
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        
        //Set Notification button - its getting added to the navigation bar from updatewithchannel()
        notificationBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        notificationBtn.setImage(UIImage(named: "notification")?.withRenderingMode(.alwaysTemplate), for: .normal)
        notificationBtn.badgeEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 15)
        notificationBtn.tintColor = UIColor.darkGray
        notificationBtn.addTarget(self, action: #selector(navigateToNotifications), for: .touchUpInside)
        
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
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
        
        //TEMPORARILY INITIATING NAMESPACE OBJECT ON CHAT LOAD
        MessageService.instance.selectedChannel?.namespace = Blockstack.shared.loadUserData()?.username
        MessageService.instance.selectedNamespace = Blockstack.shared.loadUserData()?.username
        
        configureTableView()
        
        readChannels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        stopTimerTest()
        self.scheduledTimerWithTimeInterval()
    }
    
    @objc func channelSelected(_ notif: Notification) {
        updateWithChannel()
    }
    
    func readChannels(){
        if Connectivity.isConnectedToInternet {
            SVProgressHUD.show()
            MessageService.instance.findAllChannel { (success) in
                if success {
                    if MessageService.instance.channels.count > 0 {
                        
                        MessageService.instance.getSetSavedNamespaceChannel(namespace: MessageService.instance.selectedNamespace!, channel: MessageService.instance.channels[0], write: false, completion: { (success) in
                            NotificationCenter.default.post(name: Notification.Name("channelDataUpdated"), object: nil)
                            self.updateWithChannel()
                        })
                        
                    } else {
                        self.title = "No channels yet!"
                    }
                }
            }
        } else {
            self.noInternetAlert()
        }
    }
    
    func updateWithChannel() {
        print("update with channel")
        SVProgressHUD.show()
        messageArray.removeAll()
        tableView.reloadData()
        let channelName = MessageService.instance.selectedChannel?.channelTitle ?? ""
        self.title = "#\(channelName)"
        self.channelFileName = (MessageService.instance.selectedChannel?.id)! + channelName
        if(MessageService.instance.selectedChannel?.namespace != nil){
            //If its a remote channel we will first retrieve channel participants from the owner's channel file
            if (MessageService.instance.selectedChannel?.namespace != Blockstack.shared.loadUserData()?.username){
                self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: notificationBtn)]
                MessageService.instance.getForeignChannelParticipants { (success) in
                    if success {
                        if(MessageService.instance.selectedChannel?.participants != ""){
                            self.retrieveMessages(completeFunc: self.readMessages)
                        }else{
                            print("remote participants found to be nil")
                            SVProgressHUD.dismiss()
                        }
                    }else{
                        print("unable to retrieve participants of remote channel")
                        SVProgressHUD.dismiss()
                    }
                }
            }else{
                let addButton = UIButton(type: .custom)
                addButton.setImage(UIImage(named: "add")?.withRenderingMode(.alwaysTemplate), for: .normal)
                addButton.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
                addButton.tintColor = UIColor.darkGray
                addButton.addTarget(self, action: #selector(addParticipantsOpen), for: .touchUpInside)
                let addButtonItem = UIBarButtonItem(customView: addButton)
                
                self.navigationItem.rightBarButtonItems = [addButtonItem, UIBarButtonItem(customView: notificationBtn)]
                retrieveMessages(completeFunc: readMessages)
            }
        }else{
            print("namespace is not set")
            SVProgressHUD.dismiss()
        }
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
        cell.usernameLabel.text = messageArray[indexPath.row].username
        cell.sentImageView.image = sentImage
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
        
        //messageTextField.endEditing(true)
        
        if (messageTextField.text != "") {
            getLocalJson(completeFunc: self.combineMessages)
        }
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
        messageTableView.reloadData()
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
            messageModel.username = username
            if(username == localUsername){
                messageModel.imageName = LetterImageGenerator.imageWith(name: username, imageBackgroundColor: "local")
            }else{
                messageModel.imageName = LetterImageGenerator.imageWith(name: username, imageBackgroundColor: "remote")
            }
            
            messageArray.append(messageModel)
            updateRowsInTable()
        }
        activateTimer = true
    }
    
    
    func combineMessages(json : JSON){
        //print("Messages are \(json)")
        
        
        let message = MessageModel()
        message.message = self.messageTextField.text!
        message.imageName = LetterImageGenerator.imageWith(name: self.localUsername, imageBackgroundColor: "local")
        let dateFormatter = DateFormatter()
        let date = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
        dateFormatter.dateFormat = "HH:mm"
        let strDate = dateFormatter.string(from: date)
        message.time = strDate
        message.username = self.localUsername
        self.sentImage = UIImage(named: "stopwatch")!
        self.messageArray.append(message)
        
        //Before updating the row in the table, we want to collect the ID of the message, that is for the progress tick to show
        //once the we post the updated JSON to the Gaia
        self.messageProgress.append(self.messageArray.count - 1)
        
        //Now update the rows
        self.updateRowsInTable()
        
        //Now combine the new message with previous messages in the JSON file and re-upload it
        var messageDictionary = json.dictionaryObject
        let timeInterval = NSDate().timeIntervalSince1970
        let newItem = ["messagebody": messageTextField.text!]
        self.messageTextField.text = ""
        
        if messageDictionary == nil{
            messageDictionary = ["\(timeInterval)" :  newItem]
            
        }else{
            messageDictionary?.updateValue(newItem, forKey: "\(timeInterval)")
        }
        
        let messageJSONText = Helper.serializeJSON(messageDictionary: messageDictionary!)
        Blockstack.shared.putFile(to: channelFileName, text: messageJSONText) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")
                DispatchQueue.main.async{
                    print("message has been posted")
                    //Message has been posted, update the tick image
                    //WE ARE JUST PICKING THE 0 INDEX, THAT MEANS THE LAST MESSAGE INDEX, NEED TO MAKE IT DYNAMIC FOR ALL MESSAGES
                    let indexPath = IndexPath.init(row: self.messageProgress[0], section: 0)
                    //let indexPath = self.messageProgress[0]
                    self.sentImage = UIImage(named: "checked_simple")!
                    self.messageTableView.beginUpdates()
                    self.messageTableView.re.reloadRows(
                        at: [indexPath],
                        with: .fade)
                    self.messageTableView.endUpdates()
                    self.messageProgress.removeAll()
                }
            }
        }
        
        
        
    }
    
    func retrieveMessages(completeFunc: @escaping (JSON) -> Void){
        
        var remoteJson : JSON = ""
        let participants = MessageService.instance.selectedChannel?.participants.arrayObject as! [String]
        print(participants)
        let dispatchGroup = DispatchGroup()
        for participant in participants {
            //saving last message string count to check in updateRemoteUserChat if there are any new messages from the remote user
            //recording 0 the first time in case the user hasn't sent a message to the channel yet
            self.participantLastMessageStringCount[participant] = 0
            dispatchGroup.enter()
            // Read data from Gaia
            Blockstack.shared.getFile(at: channelFileName, username: participant) { response, error in
                if error != nil {
                    print("get file error for \(participant)")
                } else {
                    print("get remote file success for \(participant)")
                    //print(response as Any)
                    let fetchResponse = (response as? String)!
                    
                    //Test to see if we got Blob Not Found error i.e., user hasn't posted any msg yet
                    //in that case we can not update the fetchResponse.count as last count of msgs
                    let arr = fetchResponse.split {$0 == " "}
                    if (arr[0] != "<?xml"){
                        self.participantLastMessageStringCount[participant] = fetchResponse.count
                        self.remoteUserLastChatStringCount = fetchResponse.count
                    }
                    
                    if(remoteJson != JSON.null && remoteJson != ""){
                        var newJson = JSON.init(parseJSON: fetchResponse)
                        for (key, var item) in newJson {
                            item["username"] = JSON(participant)
                            newJson[key] = item
                        }
                        if(newJson.dictionaryObject != nil){
                            let combinedDict = remoteJson.dictionaryObject?.merging(newJson.dictionaryObject!) { $1 }
                            remoteJson = JSON(combinedDict as Any)
                        }
                        
                    }else{
                        remoteJson = JSON.init(parseJSON: fetchResponse)
                        for (key, var item) in remoteJson {
                            item["username"] = JSON(participant)
                            remoteJson[key] = item
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        
        
//        dispatchGroup.enter()
//        // Read data from Gaia'
//        Blockstack.shared.getFile(at: channelFileName) { response, error in
//            if error != nil {
//                print("get local file error")
//            } else {
//                print("get local file success")
//                //print(response as Any)
//                localJson = JSON.init(parseJSON: (response as? String)!)
//                for (key, var item) in localJson {
//                    item["username"] = JSON(self.localUsername)
//                    localJson[key] = item
//                }
//            }
//            dispatchGroup.leave()
//        }

        dispatchGroup.notify(queue: .main) {
            print("Both functions complete 👍")
            //print(localJson)
            print(remoteJson)
//            var combinedMessages : JSON = localJson
//            if(localJson != JSON.null && localJson != "" && remoteJson != JSON.null && remoteJson != ""){
//                let combinedDict = localJson.dictionaryObject?.merging(remoteJson.dictionaryObject!) { $1 }
//                combinedMessages = JSON(combinedDict as Any)
//            }
            completeFunc(remoteJson)
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
            SVProgressHUD.dismiss()
        }
    }
    
    func getLocalJson(completeFunc: @escaping (JSON) -> Void){
        var localJson : JSON = ""
        Blockstack.shared.getFile(at: channelFileName) { response, error in
            if error != nil {
                print("get local file error")
            } else {
                print("get local file success")
                //print(response as Any)
                localJson = JSON.init(parseJSON: (response as? String)!)
                for (key, var item) in localJson {
                    item["username"] = JSON(self.localUsername)
                    localJson[key] = item
                }
            }
            DispatchQueue.main.async{
                completeFunc(localJson)
            }
        }
    }
    @objc func updateRemoteUserChat(){
        //TEMPORARY IMPLEMENTATION OF NOTIFICATION SERVICE
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.checkNotifications()
                NotificationService.instance.retrieve_accepted_notifications()
            }
        }
        
        if activateTimer == true {
            if !Connectivity.isConnectedToInternet {
                self.noInternetAlert()
            } else {
                
                print("counting..")
                if(MessageService.instance.selectedChannel?.participants != ""){
                let participants = MessageService.instance.selectedChannel?.participants.arrayObject as! [String]
                    print(participants)
                    for participant in participants {
                        if(participant != self.localUsername){
                            print("participant name in update remote userchat is \(participant)")
                            if self.participantLastMessageStringCount[participant] == nil {
                                self.participantLastMessageStringCount[participant] = 0
                            }
                            Blockstack.shared.getFile(at: self.channelFileName, username: participant) { response, error in
                                if error != nil {
                                    print("get file error")
                                } else {
                                    print("get remote file success")
                                    print(response as Any)
                                    let fetchResponse = (response as? String)!
                                    let arr = fetchResponse.split {$0 == " "}
                                    
                                    if (arr[0] != "<?xml" && fetchResponse.count > self.participantLastMessageStringCount[participant]!){
                                    DispatchQueue.main.async {
                                        
                                            let parseJson = JSON.init(parseJSON: (response as? String)!)
                                            let sortedResults = parseJson.sorted { $0 < $1 }
                                        
                                            let message = MessageModel()
                                            message.message = "\(sortedResults.last?.1["messagebody"] ?? "New Message")"
                                            message.imageName = LetterImageGenerator.imageWith(name: participant, imageBackgroundColor: "remote")
                                            let dateFormatter = DateFormatter()
                                            let date = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
                                            dateFormatter.dateFormat = "HH:mm"
                                            let strDate = dateFormatter.string(from: date)
                                            message.time = strDate
                                            message.username = participant
                                            self.messageArray.append(message)
                                            self.participantLastMessageStringCount[participant] = fetchResponse.count
                                            self.remoteUserLastChatStringCount = fetchResponse.count
                                            self.updateRowsInTable()
                                            }
                                    }

                                }
                            }
                        }
                    }
                }else{
                    MessageService.instance.getForeignChannelParticipants { (success) in
                        print("tried fetching participants from remote file again")
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
                    if resultJSON["result"] != "error"{
                        SVProgressHUD.dismiss()
                        DispatchQueue.main.async {
                            self.notificationBtn.badge = resultJSON["result"].stringValue
                        }
                        
                    }else{
                        //print("error")
                        self.notificationBtn.badge = nil
                    }
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
        }
    }
    
    @objc func navigateToNotifications(){
        performSegue(withIdentifier: "goToNotifications", sender: self)
    }
    
    @IBAction func menuButtonToggle(_ sender: Any) {
        messageTextField.endEditing(true)
        self.revealViewController().revealToggle(self)
    }
    
    func noInternetAlert(){
        let alert = UIAlertController(title: "Error", message: "No internet connection", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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


