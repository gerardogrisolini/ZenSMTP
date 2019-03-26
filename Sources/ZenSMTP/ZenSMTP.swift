//
//  ZenSMTP.swift
//  ZenSMTP
//
//  Created by admin on 01/03/2019.
//

import NIO
import NIOSSL

public enum SmtpError: Error {
    case sendingEmail(reason: String)
    case generic
}

public class ZenSMTP {

    private let eventLoopGroup: EventLoopGroup
    private var eventLoop: EventLoop {
        return self.eventLoopGroup.next()
    }
    private var config: ServerConfiguration!
    private var clientHandler: NIOSSLClientHandler? = nil

    public init(config: ServerConfiguration, eventLoopGroup: EventLoopGroup) {
        self.config = config
        self.eventLoopGroup = eventLoopGroup
        if let cert = config.cert, let key = config.key {
            let configuration = TLSConfiguration.forServer(
                certificateChain: [cert],
                privateKey: key)
            let sslContext = try! NIOSSLContext(configuration: configuration)
            clientHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: config.hostname)
        }
    }
    
    let printHandler: (String) -> Void = { str in
        print(str)
    }

    public func send(email: Email, handler: @escaping (String?) -> ()) {
        let emailSentPromise: EventLoopPromise<Void> = eventLoop.makePromise()
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                let handlers: [ChannelHandler] = [
                    PrintEverythingHandler(handler: self.printHandler),
                    SMTPResponseDecoder(),
                    SMTPRequestEncoder(),
                    SendEmailHandler(configuration: self.config,
                                     email: email,
                                     allDonePromise: emailSentPromise)
                ]
                if let clientHandler = self.clientHandler {
                    return channel.pipeline.addHandler(clientHandler).flatMap {
                        channel.pipeline.addHandlers(handlers)
                    }
                } else {
                    return channel.pipeline.addHandlers(handlers)
                }
            }
            .connect(host: config.hostname, port: config.port)
        
        bootstrap.cascadeFailure(to: emailSentPromise)
        
        func completed(_ error: String?) {
            bootstrap.whenSuccess { $0.close(promise: nil) }
            handler(nil)
        }

        emailSentPromise.futureResult
            .map { _ in
                completed(nil)
             }
            .whenFailure { error in
                completed(error.localizedDescription)
            }
    }
}
