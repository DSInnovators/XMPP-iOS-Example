# XMPP-iOS-Example

This is an example project which was created to figure out how to integrate [Tigase](https://github.com/tigase/tigase-swift) library in an iOS project for implementing chat messaging feature using XMPP.

The [documentation](https://docs.tigase.net/tigase-swift/master-snapshot/Tigase_Swift_Guide/html/) for Tigase is not very detailed. We had to figure out a lot of things by diving into the implementation details. This project will help anyone in the future to integrate Tigase in their project without much hassle.


# Todos before running

- Specify your XMPP server password inisde `func  setCredentials(jabberId: String)` function
- If you want to use MUC module, specify your MUC Server using the `private  let  mucServer`variable inside `XMPPClientService`class. MUC Servers typically look like this -> `MUC Subdomain + XMPP Domain`. Example -> `conference.abcdapp.dsinnovators.com`

# Key Features

Using this example project, you can try out the following XMPP features:
- Connect to XMPP Server
- Retrieve Archived Messages using MAM moduel
- Send/Receive one-to-one message to/from another user
- Send/Receive typing status for one-to-one messages
- Create new group chat room with initial invitees using MUC module
- Send/Receive message to/from group chat
- Add/Remove someone from group chat (for Admins)