import Starscream

private let chatURL = NSURL(string: "wss://vapor-chat.herokuapp.com/chat")!

internal class ChatModel {

    let webSocket = WebSocket(url: chatURL as URL)
    lazy var username: String! = "null"

    // Probably not best to store here, but just trying to get something up quickly
    weak var controller: VaporChatController?

    init(_ controller: VaporChatController) {
        self.controller = controller
    }

    func start() {
        webSocket.onConnect = { [unowned webSocket, weak self] in
            guard let username = self?.username else { return }

            webSocket.write(string:"{\"username\":\"\(username)\"}")

        }

        webSocket.onText = { [unowned self] text in
            guard let data = text.data(using: String.Encoding.utf8) else { return }
            guard let js = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return }
            guard
                let username = (js as! Dictionary)["username"]! as? String,
                let content = (js as! Dictionary)["message"]! as? String
                else { return }
            let message = ChatMessage(sentBy: .opponent, content: "\(username): \(content)", timeStamp: nil, imageUrl: nil)
            self.controller?.addNewMessage(message: message)
        }

        webSocket.onDisconnect = { [weak self] err in
            self?.controller?.showDisconnect()
        }

        webSocket.connect()
    }

    func send(msg: String) {
        let json = "{\"message\":\"\(msg)\"}"
        webSocket.write(string:json)
    }
}

