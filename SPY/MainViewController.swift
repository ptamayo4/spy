//
//  MainViewController.swift
//  SPY
//
//  Created by Patrick Tamayo on 4/20/17.
//  Copyright © 2017 Patrick Tamayo. All rights reserved.
//

import UIKit
import CoreLocation

protocol LoginDelegate: class {
    func passAlias(alias: String)
}

class MainViewController: UIViewController {
    var delegate: LoginDelegate?

    @IBOutlet weak var countDownLabel: UILabel!
    var missionTimer: Timer = Timer()
    var count: Int = 300
    
    var activationTimer: Timer = Timer()
    var activationCount = 600
    
    func startCountdown(){
        missionTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(myUpdate), userInfo: nil, repeats: true)
    }
    
    func startActivationCountdown(){
        activationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(activationUpdate), userInfo: nil, repeats: true)
    }
    
    //To check to see if the gameTimer has run out yet
    func myUpdate() {
        if(count > 0) {
            count -= 1
            let minutesLeft = Int(count) / 60 % 60
            let secondsLeft = Int(count) % 60
            if secondsLeft < 10 {
                countDownLabel.text = "\(minutesLeft):0\(secondsLeft)"
            } else {
                countDownLabel.text = "\(minutesLeft):\(secondsLeft)"
            }
        }
    }
    
    //For checking to see if the host has gotten a guest yet
    func activationUpdate(){
        if(activationCount > 0) {
            activationCount -= 1
        }
        if activationCount % 10 == 0 {
            checkGameStatus()
        }
    }

    
    var oldTime = CACurrentMediaTime()
    var currentAgent: Agent?
    var aliasString = ""
    var agentList: [Agent] = [Agent]()
    var sessions: [NSDictionary] = [NSDictionary]()
    var playerGameSession: GameSession?

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var transmitButton: UIButton!
    
    override func viewDidLoad() {
        countDownLabel.text = ""
        super.viewDidLoad()
        retrieveAgent(alias: aliasString)
        getAllSessions()
        //All this button bullshit should be moved to a different function
        activateButton.titleLabel?.text = "test"
        statusLabel.text = ""
        transmitButton.isEnabled = false
        transmitButton.setTitle("Inactive", for: UIControlState.disabled)
        transmitButton.setTitle("Transmit", for: UIControlState.normal)
        transmitButton.backgroundColor = UIColor.black
    }
    
    func retrieveAgent(alias: String){
        RequestModel.getAgent(alias: alias, completionHandler: {
            data, response, error in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    if let i = jsonResult["user"] {
                        print("Didn't find that user, now creating")
                        var agent = Agent(alias: self.aliasString)
                        self.addAgent(agent: agent)
                        self.retrieveAgent(alias: alias)
                    } else {
                        let a = String(describing: jsonResult["alias"]!)
                        if let foundAgent: Agent = Agent(alias: a) {
                            self.agentList.append(foundAgent)
                        }
                    }
                } else {
                    print("User Result Failed")
                }
            } catch {
                print("error \(error)")
            }
        })
        welcome()
    }
    
    func addAgent(agent: Agent){
        RequestModel.addAgent(agent: agent, completionHandler: {
            data, response, error in
            do {
                if data != nil {
                    print("Agent added succesfully")
                } else {
                    print("error when adding agent")
                }
            }
        })
        
    }
    
    func addItemAPICall(obj: String){
        RequestModel.addTaskWithObjective(objective: obj, completionHandler: {
            data, response, error in
            do {
                if data != nil {
                    print("Item succesfully added")
                } else {
                    print("hmmm")
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func welcome(){
        self.statusLabel.text = "Welcome Agent"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            if let agent: Agent = self.agentList[0] {
                self.currentAgent = agent
                self.statusLabel.text = "Agent \(self.currentAgent!.alias): Inactive"
            }
        })
    }
    
    //Contact button is pressed upon user loading app and deciding if they want a contract or not
    
    @IBOutlet weak var activateButton: UIButton!
    
    @IBAction func activateButtonPressed(_ sender: UIButton) {
        var openSeshIndex = checkTimes()
        currentAgent?.active = true
        
        activateButton.isEnabled = false
        self.transmitButton.isEnabled = true
        
        if openSeshIndex != -1 {
            if let foundSession = sessions[openSeshIndex] as? NSDictionary{
                if let host = foundSession["host"] as? String{
                    if host != currentAgent?.alias {
                        
                        let joinedSession = GameSession()
                        
                        joinedSession.host = String(describing: foundSession["host"]!)
                        joinedSession.guest = currentAgent?.alias
                        joinedSession.id = String(describing: foundSession["_id"]!)
                        
                        addGuestToGame(guest: joinedSession.guest!, session: joinedSession)
                        
                        statusLabel.text = "Mission: Rendezvous with Agent \(joinedSession.host!)"
                        currentAgent?.inSession = true
                        self.transmitButton.backgroundColor = UIColor.red
                        startCountdown()
                    }
                }
            }
        } else {
            print("Session Not Found, creating session")
            startActivationCountdown()
            makeSession()
        }
        
        activateButton.setTitle("Activate", for: UIControlState.normal)
        activateButton.setTitle("DISABLED", for: UIControlState.disabled)
        
    }
    
    func checkTimes() -> Int{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzzz"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        
        for (index, s) in self.sessions.enumerated(){
            let dateStr = s["session_creation_time"] as! String
            let date = dateFormatter.date(from: dateStr)
            var delta = date?.timeIntervalSinceNow as! Double
            delta = -delta
            if delta < 60 {
                if String(describing: s["host"]!) != currentAgent!.alias {
                    print("Session found with delta: \(delta)")
                    print(index)
                    return index
                } else {
                    print("matched host name")
                }
            }
        }
        print(-1)
        return -1
    }
    
    func makeSession(){
        
        let now = Date()
        let newGameSession = GameSession()
        newGameSession.host = currentAgent?.alias
        newGameSession.session_creation_time = String(describing: now)
        newGameSession.team = currentAgent?.team
        playerGameSession = newGameSession
        
        RequestModel.createSession(game: newGameSession, completionHandler: {
            data, response, error in
            do {
                if data != nil {
                    print("Session Added Succesfully")
                    print(data)
                } else {
                    print("error when adding agent")
                }
            }
        })
    }
    
    
    //Idea here is to grab current location and time of the button press. Time matters more, location to to determine if variance from activation location is within constraints
    
    @IBAction func transmitButtonPressed(_ sender: UIButton) {
        if let agent = currentAgent {
            if agent.active {
                print("active transmission")
            } else {
                statusLabel.text = "Must Activate before transmission"
            }
        }
    }
    
    func getAllSessions(){
        RequestModel.getAllSessions(completionHandler: {
            data, response, error in
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    for game in jsonArray {
                        if let gameDict = game as? NSDictionary {
//                            print("grabbing session")
                            self.sessions.append(gameDict)
                        }
                    }
                }
            } catch {
                print(error)
            }
        })
    }
    
    func addGuestToGame(guest: String, session: GameSession) {
        RequestModel.addGuest(game: session, guest: currentAgent!, completionHandler: {
            data, response, error in
            do {
                if data != nil {
                    print("Guest Added Successfully")
                    print(data)
                } else {
                    print("error when adding guest to Game Session")
                }
            }
        })
    }
    
    func checkGameStatus(){
        print("checking now")
        //CHECK STATUS OF SESSION, SEE IF GUEST EXISTS, and if so destroy the activation timer and start the game timer, activate transmit button and change color as well
    }
    
    func passAlias(alias: String) {
        print(alias)
    }

}



