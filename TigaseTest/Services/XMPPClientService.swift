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

        print("Notifying event bus that we are interested in ArchivedMessageReceivedEvent" +
            " which is fired after an Archived(Old) message is received");
        client.eventBus.register(handler: self, for: MessageArchiveManagementModule.ArchivedMessageReceivedEvent.TYPE);

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

        print("Registering module for fetching old messages..");
        _ = client.modulesManager.register(MessageArchiveManagementModule());
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
        case let archivedMessage as MessageArchiveManagementModule.ArchivedMessageReceivedEvent:
            self.archivedMessageReceived(archivedMessage: archivedMessage)
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
        presenceModule.setPresence(show: Presence.Show.online, status: nil, priority: nil);
    }

    func fetchChatArchives(for username: String?) {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 1
        dateComponents.timeZone = TimeZone(abbreviation: "BST") // Japan Standard Time
        dateComponents.hour = 0
        dateComponents.minute = 0

        let userCalendar = Calendar.current
        let startDate = userCalendar.date(from: dateComponents)

        //with param may be used when we want to fetch messages with a specific user, nil specifies that we are interested in ALL messages
        //rsm param may be used for pagination. ex - rsm: RSM.Query(from: 0, max: 2)
        let mamModule: MessageArchiveManagementModule = self.client.modulesManager.getModule(MessageArchiveManagementModule.ID)!;
        mamModule.queryItems(componentJid: nil, node: nil, with: nil, start: startDate, end: Date(), queryId: "", rsm: nil, onSuccess: { (queryId, success, result) in
        }) { (error, stanza) in
        }
    }

    func archivedMessageReceived(archivedMessage: MessageArchiveManagementModule.ArchivedMessageReceivedEvent) {
        print(archivedMessage.message.from, archivedMessage.message.to)
        print(archivedMessage.message.body, archivedMessage.timestamp)
    }
}
