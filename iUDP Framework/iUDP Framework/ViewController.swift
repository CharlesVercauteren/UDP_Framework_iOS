//
//  ViewController.swift
//  iUDP Framwork
//
//  Created by Charles Vercauteren on 11/02/2022.
//


import UIKit
import Network

// Arduino (server)
let IP_ADDRESS = "10.89.1.90"
let PORT_SERVER: UInt16 = 2000

var udpClient = iUDPFramework()
var clientReady = false
var reply = ""

class ViewController: UIViewController {

   
    @IBOutlet weak var textToSend: UITextField!
    @IBOutlet weak var textReceived: UITextField!
    
    //Arduino UDP server properties
    let portServer = PORT_SERVER
    //var server: NWConnection?
    var ipAddress = IP_ADDRESS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        udpClient.delegate = self
        
        udpClient.setServer(ipAddress: ipAddress, port: portServer)
        udpClient.connect()
    }
    
    @IBAction func sendPacket(_ sender: Any) {
        udpClient.sendCommand(command: textToSend.text ?? "Fout opgetreden")
    }
}

extension ViewController:UDPMessages {
    
    func connectionReady() {
        clientReady = true
    }
    
    func receivedMessage(message: String) {
        textReceived.text = message
    }
}



