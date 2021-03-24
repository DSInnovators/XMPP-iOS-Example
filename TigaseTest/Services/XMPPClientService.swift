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

    private let mucServer = ""

    private var archivedMessages: [MessageArchiveManagementModule.ArchivedMessageReceivedEvent]!

    private var pageSize = 2000

    private var isCredentialsSet: Bool = false

    private var myJID: String!

    private var client: XMPPClient!

    private var eventsToRegister = [SessionEstablishmentModule.SessionEstablishmentSuccessEvent.TYPE,
                                    SocketConnector.DisconnectedEvent.TYPE,
                                    MessageArchiveManagementModule.ArchivedMessageReceivedEvent.TYPE,
                                    MessageModule.MessageReceivedEvent.TYPE,
                                    MessageDeliveryReceiptsModule.ReceiptEvent.TYPE,
                                    MucModule.InvitationReceivedEvent.TYPE,
                                    MucModule.YouJoinedEvent.TYPE,
                                    MucModule.MessageReceivedEvent.TYPE] as [Event]

    private init() {
        self.client = XMPPClient()
        
        self.registerModules()
        
        self.registerForEvents()
    }

    deinit {
        self.client.eventBus.unregister(handler: self, for: self.eventsToRegister)
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

        print("Registering module for multi-user chat (MUC)..");
        _ = client.modulesManager.register(MucModule());

//        Cannot register ChatStateNotificationsModule as its init is internal. Also, state notification works withouth explicitly registering this module
//        print("Registering module for getting chat state notification (user typing notification)..");
//        _ = client.modulesManager.register(ChatStateNotificationsModule());
    }

    private func registerForEvents() {
        self.client.eventBus.register(handler: self, for: self.eventsToRegister)
    }
    
    private func setCredentials(userJID: String, password: String) {
        self.myJID = userJID

        let jid = BareJID(userJID);
        
        self.client.connectionConfiguration.setUserJID(jid);
        self.client.connectionConfiguration.setUserPassword(password);
        
        //Might be a better approach to specify source.. need to search more
//        self.client.sessionObject.setUserProperty(SessionObject.RESOURCE, value: "SPECIFY RESOURCE HERE")

        self.isCredentialsSet = true
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
        case let invitation as MucModule.InvitationReceivedEvent:
            self.acceptRoomInvitation(roomJid: invitation.invitation!.roomJid)
        case let mrj as MucModule.YouJoinedEvent:
            mucRoomJoined(mrj);
        case let mmr as MucModule.MessageReceivedEvent:
            mucMessageReceived(mmr);
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
        self.setCredentials(userJID: jabberId, password: "SPECIFY SERVER PASSWORD HERE");
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
                completion(self.archivedMessages.reversed())
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

    func createNewChatRoom(roomName: String, inviteeJIDs: [String]) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let newRoomId = "group-" + UIDGenerator.nextUid
        let myRoomNickname = self.myJID.components(separatedBy: "@")[0]

        _ = mucModule.join(roomName: newRoomId, mucServer: self.mucServer, nickname: myRoomNickname, password: nil, ifCreated: { [weak self] (room) in

            /*
             After creating a room, we need to set its configurations. Until room has been configured, the room
             stays in a LOCKED state and as a result only the owner can except the room. If in LOCKED state, anyone
             except the owner tries to enter the room, he will receive a <item-not-found/> error
             https://xmpp.org/extensions/xep-0045.html#enter-locked
             */
            self?.setConfigurations(to: room, roomName: roomName)
            self?.addInitialParticipants(to: room, inviteeJIDs: inviteeJIDs)
        })
    }

    private func setConfigurations(to room: Room, roomName: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        //Setting room subject
        mucModule.setRoomSubject(roomJid: BareJID(room.jid), newSubject: roomName)

        let roomConfiguration = JabberDataElement(type: .submit)

        roomConfiguration.addField(variableName: "muc#roomconfig_roomname", value: roomName) //Setting room Name
        roomConfiguration.addField(variableName: "muc#roomconfig_roomdesc",value: roomName) //Setting room description
        roomConfiguration.addField(variableName: "muc#roomconfig_persistentroom", value: "1") //Making room Persistent
        roomConfiguration.addField(variableName: "muc#roomconfig_membersonly", value: "1") //Making room "Member Only"
        roomConfiguration.addField(variableName: "muc#roomconfig_allowinvites", value: "1") //Allowing occupants to invite others

        mucModule.setRoomConfiguration(roomJid: room.jid, configuration: roomConfiguration, onSuccess: {}, onError: { (error) in
            print(error)
        })
    }

    private func addInitialParticipants(to room: Room, inviteeJIDs: [String]) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        var roomAffiliations = [MucModule.RoomAffiliation]()

        for invitee in inviteeJIDs {
            let roomAffiliation = MucModule.RoomAffiliation(jid: JID(invitee), affiliation: .member)
            roomAffiliations.append(roomAffiliation)
        }

        mucModule.setRoomAffiliations(to: room, changedAffiliations: roomAffiliations) { (error) in
            print(error)
        }
    }

    private func acceptRoomInvitation(roomJid: BareJID) {
        //We are accepting an invitation by joining the room

        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let roomName = roomJid.stringValue.components(separatedBy: "@")[0]
        let mucServer = roomJid.stringValue.components(separatedBy: "@")[1]

        let myRoomNickname = self.myJID.components(separatedBy: "@")[0]

        _ = mucModule.join(roomName: roomName, mucServer: mucServer, nickname: myRoomNickname, password: nil)
    }

    func joinRoom(roomId: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let myRoomNickname = self.myJID.components(separatedBy: "@")[0]
        _ = mucModule.join(roomName: roomId, mucServer: self.mucServer, nickname: myRoomNickname, password: nil)
    }

    func sendMessageToRoom(roomId: String, message: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let room = mucModule.roomsManager.getRoom(for: BareJID(roomId + "@" + self.mucServer))
        room?.sendMessage(message)
    }

    func addUserToExistingRoom(roomId: String, userJID: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        if let room = mucModule.roomsManager.getRoom(for: BareJID(roomId + "@" + self.mucServer)) {
            let myRoomNickname = self.myJID.components(separatedBy: "@")[0]

            if room.presences[myRoomNickname]?.affiliation == MucAffiliation.owner {
                //Owners/Admins can add new users via adding Affiliation directly. They can also add by sending invitation.
                let roomAffiliation = MucModule.RoomAffiliation(jid: JID(userJID), affiliation: .member, nickname: nil, role: .participant)
                mucModule.setRoomAffiliations(to: room, changedAffiliations: [roomAffiliation]) { (error) in
                    print(error)
                }
            } else {
                //Members can add new users by only sending invitations. They don't have permission to add affiliation directly
                mucModule.invite(to: room, invitee: JID(userJID), reason: nil)
            }
        }
    }

    func removeUserFromExistingRoom(roomId: String, userJID: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let roomAffiliation = MucModule.RoomAffiliation(jid: JID(userJID), affiliation: .none)

        let room = mucModule.roomsManager.getRoom(for: BareJID(roomId + "@" + self.mucServer))

        mucModule.setRoomAffiliations(to: room!, changedAffiliations: [roomAffiliation]) { (error) in
            print(error)
        }
    }

    func updateExistingUserAffiliation(to affiliation: MucAffiliation, roomId: String, userJID: String) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        let roomAffiliation = MucModule.RoomAffiliation(jid: JID(userJID), affiliation: affiliation)

        let room = mucModule.roomsManager.getRoom(for: BareJID(roomId + "@" + self.mucServer))

        mucModule.setRoomAffiliations(to: room!, changedAffiliations: [roomAffiliation]) { (error) in
            print(error)
        }
    }

    private func mucRoomJoined(_ event: MucModule.YouJoinedEvent) {
        let mucModule: MucModule = client.modulesManager.getModule(MucModule.ID)!

        //Fetching all affiliated members of the room after joining
        mucModule.getRoomAffiliations(from: event.room, with: .member) { (affiliations, error) in
            guard error == nil else {
                return
            }
        }
    }

    func mucMessageReceived(_ receivedMessage: MucModule.MessageReceivedEvent) {
        NotificationCenter.default.post(name: NSNotification.Name("newGroupMessageReceived"), object: nil, userInfo: ["receivedMessage": receivedMessage])
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

extension JabberDataElement {
    func addField(variableName: String, value: String) {
        let element =  Field.createFieldElement(name: variableName, type: nil)
        element.addChild(Element(name: "value", cdata: value));

        if let field = Field(from: element) {
            self.addField(field)
        }
    }
}
