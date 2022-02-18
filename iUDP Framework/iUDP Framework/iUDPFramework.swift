//
//  iUDPFramework.swift
//
//  Created by Charles Vercauteren on 11/02/2022.
//

import Foundation
import Network

// Network status
let STATUS_INIT = "Init connection."
let STATUS_CONNECTED = "Connected."
let STATUS_SETUP = "Setting up connection."
let STATUS_WAITING = "Waiting for connection."
let STATUS_FAILED = "Failed to make connection."
let STATUS_CANCELLED = "Connection cancelled."
let STATUS_UNKNOWN = "Status unknown."
let STATUS_COMMAND_UNKNOWN = "Command not supported."

// Extensies
protocol UDPMessages {
    func connectionReady()                  // Verbinding komt in STATUS_CONNECTED
    func receivedMessage(message: String)   // Een pakket met inhoud "message" is ingelezen
}

class iUDPFramework {
    var delegate: UDPMessages?
    var connectionToServer: NWConnection?
    var status = STATUS_UNKNOWN
    
    var portServer: UInt16 = 0
    var ipServer = ""
    
    func setServer(ipAddress: String, port: UInt16) {
        ipServer = ipAddress
        portServer = port
    }
    
    func connect(){
        // If reconnecting disconnect
        connectionToServer?.cancel()
        
        //Create host/port
        let host = NWEndpoint.Host(ipServer)
        let port = NWEndpoint.Port(rawValue: portServer) ?? NWEndpoint.Port.any     // .any is poort 0, vermijd nil
        
        // Maak nieuwe verbinding, installeer update handler en activeer verbinding
        connectionToServer = NWConnection(host: host, port: port, using: NWParameters.udp)
        connectionToServer?.stateUpdateHandler = {(newState) in self.stateUpdateHandler(newState: newState) }
        connectionToServer?.start(queue: .main)
    }
    
    private func stateUpdateHandler(newState: NWConnection.State){
        // Wordt aangeroepen bij verandering van de status van de verbinding
        switch (newState){
        case .setup:
            status = STATUS_SETUP
        case .waiting:
            status = STATUS_WAITING
        case .ready:
            status = STATUS_CONNECTED
            // Signaleer dat de verbinding klaar is om
            // gebruikt te worden
            delegate?.connectionReady()
        case .failed:
            status = STATUS_FAILED
            // Bij schakelen naar andere app verliezen we de verbinding
            // verbind terug
            connect()
        case .cancelled:
            status = STATUS_CANCELLED
        default:
            status = STATUS_UNKNOWN
        }
    }
    
    func sendCommand(command: String) {
        // Verzend commando en wacht op antwoord
        connectionToServer!.send(content: command.data(using: String.Encoding.ascii),
                                 completion: .contentProcessed({
                    error in
                    if error == nil {
                            self.receiveMessage()
                        }
                    else {
                            print(error)
                        }
                }
            )
        )
    }
    
    private func receiveMessage() {
        var reply = ""
        connectionToServer!.receiveMessage (completion: {(content, context, isComplete, error) in
            if isComplete {
                let replyLocal = String(decoding: content ?? Data() , as:   UTF8.self)
                reply = replyLocal
                // Signaleer dat een pakket is ontvangen.
                self.delegate?.receivedMessage(message: reply)
            }
            else {
                self.status = STATUS_UNKNOWN
            }
        })
    }
    
}
