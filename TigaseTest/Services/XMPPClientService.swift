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

    private var archivedMessages: [MessageArchiveManagementModule.ArchivedMessageReceivedEvent]!

    private var pageSize = 2000

    private var isCredentialsSet: Bool = false

    private var client: XMPPClient!
    private init() {
        self.client = XMPPClient()
        
        self.registerModules()
        
        print("Notifying event bus that we are interested in SessionEstablishmentSuccessEvent" +
            " which is fired after client is connected");
        self.client.eventBus.register(handler: self, for: SessionEstablishmentModule.SessionEstablishmentSuccessEvent.TYPE);
        print("Notifying event bus that we are interested in DisconnectedEvent" +
            " which is fired after client is connected");
        self.client.eventBus.register(handler: self, for: SocketConnector.DisconnectedEvent.TYPE);

        print("Notifying event bus that we are interested in ArchivedMessageReceivedEvent" +
            " which is fired after an Archived(Old) message is received");
        self.client.eventBus.register(handler: self, for: MessageArchiveManagementModule.ArchivedMessageReceivedEvent.TYPE);

        print("Notifying event bus that we are interested in MessageReceivedEvent" +
            " which is fired after a message is received");
        self.client.eventBus.register(handler: self, for: MessageModule.MessageReceivedEvent.TYPE);

        print("Notifying event bus that we are interested in ReceiptEvent" +
            " which is fired after a message is delivered");
        self.client.eventBus.register(handler: self, for: MessageDeliveryReceiptsModule.ReceiptEvent.TYPE);
    }

    deinit {
        self.client.eventBus.unregister(handler: self, for: [SessionEstablishmentModule.SessionEstablishmentSuccessEvent.TYPE, SocketConnector.DisconnectedEvent.TYPE, MessageArchiveManagementModule.ArchivedMessageReceivedEvent.TYPE,MessageModule.MessageReceivedEvent.TYPE])
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

        print("Registering module for message receipt..");
        _ = client.modulesManager.register(MessageDeliveryReceiptsModule());

//        Cannot register ChatStateNotificationsModule as its init is internal. Also, state notification works withouth explicitly registering this module
//        print("Registering module for getting chat state notification (user typing notification)..");
//        _ = client.modulesManager.register(ChatStateNotificationsModule());
    }
    
    private func setCredentials(userJID: String, password: String) {
        let jid = BareJID(userJID);
        
        self.client.connectionConfiguration.setUserJID(jid);
        self.client.connectionConfiguration.setUserPassword(password);
        
        //Might be a better approach to specify source.. need to search more
        self.client.sessionObject.setUserProperty(SessionObject.RESOURCE, value: "SSFAPP")

        self.isCredentialsSet = true
        
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
            NotificationCenter.default.post(name: NSNotification.Name("didConnect"), object: nil)
        case is SocketConnector.DisconnectedEvent:
            print("Client is disconnected.");
            NotificationCenter.default.post(name: NSNotification.Name("didDisconnect"), object: nil)
        case let archivedMessage as MessageArchiveManagementModule.ArchivedMessageReceivedEvent:
            self.archivedMessageReceived(archivedMessage: archivedMessage)
        case let receivedMessage as MessageModule.MessageReceivedEvent:
            self.newMessageReceived(receivedMessage: receivedMessage)
        case let receipt as MessageDeliveryReceiptsModule.ReceiptEvent:
            print(receipt)
        default:
            print("unsupported event", event);
        }
    }

    /// Called when session is established
    private func sessionEstablished() {
        print("Now we are connected to server and session is ready..");
        
        //Need to set online presence explicitly
        self.setOnlinePresence()
    }

    func setCredentials(jabberId: String) {
        self.setCredentials(userJID: jabberId, password: "12345678ssf");
    }

    func removeCredentials() {
        self.isCredentialsSet = false
    }
    
    func connect() {
        guard self.isCredentialsSet else {
            return
        }

        NotificationCenter.default.post(name: NSNotification.Name("didStartToConnect"), object: nil)
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

    func fetchChatArchives(currentPage: Int = 1, completion: @escaping(([MessageArchiveManagementModule.ArchivedMessageReceivedEvent]) -> ())) {

        //Reset data when fetching first page
        if currentPage == 1 {
            self.archivedMessages = [MessageArchiveManagementModule.ArchivedMessageReceivedEvent]()
        }

        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 1
        dateComponents.day = 1
        dateComponents.timeZone = TimeZone(abbreviation: "BST") // Japan Standard Time
        dateComponents.hour = 0
        dateComponents.minute = 0

        let userCalendar = Calendar.current
        let startDate = userCalendar.date(from: dateComponents)
        let endDate = userCalendar.date(byAdding: .hour, value: 1, to: Date())

        //with param may be used when we want to fetch messages with a specific user, nil specifies that we are interested in ALL messages
        //rsm param may be used for pagination. ex - rsm: RSM.Query(from: 0, max: 2)
        let mamModule: MessageArchiveManagementModule = self.client.modulesManager.getModule(MessageArchiveManagementModule.ID)!;
        mamModule.queryItems(componentJid: nil, node: nil, with: nil, start: startDate, end: endDate, queryId: "", rsm: RSM.Query(from: (currentPage - 1) * self.pageSize, max: self.pageSize), onSuccess: { (queryId, isCompleted, result) in
            if isCompleted {
                completion(self.archivedMessages)
            } else {
                self.fetchChatArchives(currentPage: currentPage + 1, completion: completion)
            }
        }) { (error, stanza) in
            print(error)
        }
    }

    func sendMessage(recipientJID: String, message: String) {
        let messageModule: MessageModule = self.client.modulesManager.getModule(MessageModule.ID)!
        let recipient = JID(recipientJID)
        if let chat = messageModule.createChat(with: recipient) {
            print("Sending message to \(recipientJID)")
            let message = chat.createMessage(message)
            message.id = UIDGenerator.nextUid //Setting Stanza Id
            message.messageDelivery = .request
            messageModule.context.writer?.write(message);
        }
    }

    func sendChatStateNotification(recipientJID: String, chatState: ChatState) {
        //Cannot use message module for sending chat state. Need to send manually. Otherwise it will get stored as an archived message
        let recipient = JID(recipientJID)
        let chatStateMessage = Message();
        chatStateMessage.to = recipient;
        chatStateMessage.type = .normal;
        chatStateMessage.chatState = chatState;

        print("Sending chat state notification to \(recipientJID)")
        self.client.context.writer?.write(chatStateMessage)
    }

    private func archivedMessageReceived(archivedMessage: MessageArchiveManagementModule.ArchivedMessageReceivedEvent) {
        self.archivedMessages.append(archivedMessage)
    }

    private func newMessageReceived(receivedMessage: MessageModule.MessageReceivedEvent) {
        switch receivedMessage.message.type {
        case .chat:
            NotificationCenter.default.post(name: NSNotification.Name("newMessageReceived"), object: nil, userInfo: ["receivedMessage": receivedMessage])
        case .normal:
            //This case will also be true when retreiving archived messages.
            self.handleChatStateMessage(chatStateMessage: receivedMessage)
        default:
            return
        }
    }

    private func handleChatStateMessage(chatStateMessage: MessageModule.MessageReceivedEvent) {
        switch chatStateMessage.message.chatState {
        //After this handler is called when retrieving archived message the chat state value will be nil
        case .composing, .paused:
            NotificationCenter.default.post(name: NSNotification.Name("chatStausChanged"), object: nil, userInfo: ["chatStateMessage": chatStateMessage])
        default:
            return
        }
    }
}
