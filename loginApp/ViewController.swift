//
//  ViewController.swift
//
//
//  Created by mtie on 6/4/20.
//  Modified by PJ Sangvong 6/4/20.
//
//  Copyright © 2020 mtie. All rights reserved.
//

import Cocoa
import PerfectLDAP

class ViewController: NSViewController {
    
    ///makes the login page to full screen
    override func viewDidAppear() {

        let presOptions: NSApplication.PresentationOptions = [.fullScreen, .autoHideMenuBar]
        let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presOptions]
        view.enterFullScreenMode(NSScreen.main!, withOptions: optionsDictionary)
    }
    
    //values outlets
    @IBOutlet var BackgroundView: NSImageView!
    @IBOutlet var usernameTxt: NSTextField!
    @IBOutlet var passwdTxt: NSSecureTextField!
    
    //views outlets
    @IBOutlet weak var loginBox: NSView!
    @IBOutlet weak var passwordLabel: NSTextField!
    @IBOutlet weak var userLabel: NSTextField!

    //gets image from Assets.xcassets
    //var backgroundUploadDefault = NSImage(named: "calvinBackgroundTwo")
    
    //gets image from directory, if the path doesn't exist, use the defult image
    var backgroundUpload = NSImage(contentsOfFile: "---PATH-TO-IMAGE---") //dir path to the background image
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BackgroundView.addSubview(loginBox) //brings loginBox to front
        BackgroundView.image = backgroundUpload
        
        //checks if user pushes return button
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func UserNameEnttry(_ sender: Any) {
        print("username entered")
    }

    @IBAction func PassEntry(_ sender: Any) {
        print("password entered")
        
    }
    
    @IBAction func loginButtonPushed(_ sender: Any) {
        print("login button pushed")
        
        let loginStatus = ldapLogin()
        if loginStatus == 0{ //success
            print("success")
            mountAndLink()
            exit(1)
        }else{
            print("failed")
            resetFields()
        }
        
    }

    func mountAndLink()
    {
        //make Hexstring
        let str = passwdTxt.stringValue
        let data1 = Data(str.utf8)
        let passwordHexString = "%" + data1.map{ String(format:"%02x", $0) }.joined(separator: "%")

        let netAppStr = "---SERVER-ADRESS-1---" //server address
        let homeDirStr = "---LOCAL-PATH-1---" //local path to mount the directory into
        let mountStatus1 = mountFile(from: netAppStr, to: homeDirStr, passwordHexString)
        
        let courseStr = "---SERVER-ADRESS-2---" //another server address
        let courseDirStr = "---LOCAL-PATH-2---" //local path to mount another directory into
        let mountStatus2 = mountFile(from: courseStr, to: courseDirStr, passwordHexString)
        
        if mountStatus1 == 0 && mountStatus2 == 0{
            print("mount success")
        }else{
            print("mount failed")
            // might want to add an extra error message that there are
            // problems on mounting
        }

    }
    
    /// Check for local accoount(s)
    ///
    /// - Parameter serverStr: Server name
    /// - Parameter localStr: Local path to mount into
    /// - Parameter passwordHexString: HexString encoded password
    ///
    /// - Returns: 0 if mount success, 1 if fails
    func mountFile(from serverStr:String,to localStr:String,_ Hexpassword:String) -> Int{
        
        let serverString = "//" + usernameTxt.stringValue + ":" + Hexpassword + serverStr

        //forms the command
        let mountTHIS = Process()
        mountTHIS.launchPath = "/sbin/mount"
        mountTHIS.arguments = ["-t", "smbfs", serverString, localStr]

        let pipe = Pipe()
        mountTHIS.standardOutput = pipe
        mountTHIS.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
               print(output)
           }

        mountTHIS.waitUntilExit()
        let mountStatus = mountTHIS.terminationStatus
    
        return Int(mountStatus)
    }
    
    /// Empty password textfied and add shake animation to the login box
    func resetFields(){
        //resetting values inside username and password text fields
        //usernameTxt.stringValue = "" //resetting username text field might be annoying
        passwdTxt.stringValue = ""
        
        //shake animation on the loginBox (text fields, labels, and login button)
        let midX = loginBox.layer?.position.x ?? 0
        let midY = loginBox.layer?.position.y ?? 0

        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.06
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 5, y: midY)
        animation.toValue = CGPoint(x: midX + 5, y: midY)
        loginBox.layer?.add(animation, forKey: "position")
    }
    
    /// check if the username and password are correct
    ///
    /// - Returns: 0 if success, 1 if fails
    func ldapLogin() -> Int {
        var loginStatus = 1
        //initialize strings
        let binddnString = "----SERVER-COMPONENT----" + usernameTxt.stringValue
                            + "----SERVER-COMPONENT----"
        let passwordString = passwdTxt.stringValue
        
        //connect to server
        let connection = try? LDAP(url: "----LDAP-URL----")
        let credential = LDAP.Login(binddn: binddnString, password: passwordString)
        
        let group = DispatchGroup()
        group.enter()
        connection?.login(info: credential) { err in
          // err should be nil if there is no error
            if err == nil{
                loginStatus = 0
                print("setlogin")
            }
            group.leave()//request done
        }
        group.wait()//wait until the request returns
        
        // delete coonnection
        connection?.delete(distinguishedName: binddnString) { err in
            // err should be nil if there is no error
        }
        
        return loginStatus
    }
    ///when requests to ldap server, the request runs on the background, and the main trend
    /// continues. Therefore, the code reachs the return statement before the loginStatus
    /// is set to 0.
    
    /// Detects the return key to activate the login function
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36{
            loginButtonPushed(1)
        }
    }
}
