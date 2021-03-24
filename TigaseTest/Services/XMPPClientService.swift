//
//  XMPPClientService.swift
//  TigaseTest
//
//  Created by Abid Rahman on 8/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import Foundation
import TigaseSwift

public class XMPPClientService: EventHandler {
    public static var shared = XMPPClientService()
    
    private var client: XMPPClient!
    private init() {
        self.client = XMPPClient()
        
        self.registerModules()
        
        print("Notifying event bus that we are interested in SessionEstablishmentSuccessEvent" +
            " which is fired after client is connected");
        client.eventBus.register(handler: self, for: SessionEstablishmentModule.SessionEstablishmentSuccessEvent.TYPE);
        print("Notifying event bus that we are interested in DisconnectedEvent" +
            " which is fired after client is connected");
        client.eventBus.register(handler: self, for: SocketConnector.DisconnectedEvent.TYPE);

        self.setCredentials(userJID: "30958@ssfapp.innovatorslab.net", password: "12345678ssf");
    }
    
    private func registerModules() {
        print("Registering modules required for authentication and session establishment");
        _ = client.modulesManager.register(AuthModule());
        _ = client.modulesManager.register(StreamFeaturesModule());
        _ = client.modulesManager.register(SaslModule());
        _ = client.modulesManager.register(ResourceBinderModule());
        _ = client.modulesManager.register(SessionEstablishmentModule());

        print("Registering module for sending/receiving messages..");
        _ = client.modulesManager.register(MessageModule());
        
        print("Registering module for handling presences..");
        _ = client.modulesManager.register(PresenceModule());
    }
    
    private func setCredentials(userJID: String, password: String) {
        let jid = BareJID(userJID);
        
        self.client.connectionConfiguration.setUserJID(jid);
        self.client.connectionConfiguration.setUserPassword(password);
        
        //Might be a better approach to specify source.. need to search more
        self.client.sessionObject.setUserProperty(SessionObject.RESOURCE, value: "SSFAPP")
        
//        No need for these...seems to work fine
//        client.connectionConfiguration.setDomain("ssfapp.innovatorslab.net")
//        client.connectionConfiguration.setServerHost("ssfapp.innovatorslab.net")
//        client.connectionConfiguration.setServerPort(9091)
    }

    /// Processing received events
    public func handle(event: Event) {
        switch (event) {
        case is SessionEstablishmentModule.SessionEstablishmentSuccessEvent:
            sessionEstablished();
        case is SocketConnector.DisconnectedEvent:
            print("Client is disconnected.");
        default:
            print("unsupported event", event);
        }
    }

    /// Called when session is established
    private func sessionEstablished() {
        print("Now we are connected to server and session is ready..");
        
        //Need to set online presence explicitly...might not be required...need more research
        self.setOnlinePresence()
    }
    
    func connect() {
        print("Connecting to server..")
        self.client.login()
    }
    
    func disconnect() {
        print("Disconnecting from server..");
        self.client.disconnect();
    }
    
    func setOnlinePresence() {
        let presenceModule: PresenceModule = self.client.modulesManager.getModule(PresenceModule.ID)!;
        print("Setting presence to DND...");
        presenceModule.setPresence(show: Presence.Show.online, status: nil, priority: nil);
    }
}
