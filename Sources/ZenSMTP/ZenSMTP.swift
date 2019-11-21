//
//  ZenSMTP.swift
//  ZenSMTP
//
//  Created by admin on 01/03/2019.
//

import NIO
import NIOSSL
import Logging

public enum SmtpError: Error {
    case sendingEmail(reason: String)
    case generic
}

public class ZenSMTP {
    
    private var logger: Logger!
    private var eventLoopGroup: EventLoopGroup!
    public var config: ServerConfiguration!
    public var clientHandler: NIOSSLClientHandler? = nil
    
    public static var mail = ZenSMTP()
        
    init() {
    }
    
    public func setup(config: ServerConfiguration, eventLoopGroup: EventLoopGroup) {
        self.logger = config.logger
        self.eventLoopGroup = eventLoopGroup
        self.config = config
        if let cert = config.cert, let key = config.key {
            let configuration = TLSConfiguration.forServer(
                certificateChain: [cert],
                privateKey: key)
            do {
                let sslContext = try NIOSSLContext(configuration: configuration)
                clientHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: config.hostname)
            } catch {
                logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            }
        }
        
        logger.info(Logger.Message(stringLiteral: "☯️ ZenSMTP started on \(config.hostname):\(config.port)"))
    }

    public func send(email: Email) -> EventLoopFuture<Void> {
        let emailSentPromise: EventLoopPromise<Void> = eventLoopGroup.next().makePromise()
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandlers(
                    [
                        PrintEverythingHandler(logger: self.logger),
                        ByteToMessageHandler(LineBasedFrameDecoder()),
                        SMTPResponseDecoder(),
                        MessageToByteHandler(SMTPRequestEncoder()),
                        SendEmailHandler(configuration: self.config,
                                         email: email,
                                         allDonePromise: emailSentPromise)
                    ],
                    position: .last
                )
            }
            .tlsConfig()
            .connect(host: config.hostname, port: config.port)
        
        bootstrap.cascadeFailure(to: emailSentPromise)
        
        return emailSentPromise.futureResult.map { () -> Void in
            bootstrap.whenSuccess { $0.close(promise: nil) }
        }
    }
}

extension ClientBootstrap {
    func tlsConfig() -> ClientBootstrap {
        // in case you don't want to use TLS which is a bad idea and _WILL SEND YOUR PASSWORD IN PLAIN TEXT_
        // just `return self`.
        guard let clientHandler = ZenSMTP.mail.clientHandler else {
            return self
        }
        
        return self.channelInitializer { channel in
            channel.pipeline.addHandler(clientHandler)
        }
    }
}

