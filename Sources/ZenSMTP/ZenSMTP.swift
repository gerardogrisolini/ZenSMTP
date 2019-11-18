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
    public var config: ServerConfiguration!
    public var clientHandler: NIOSSLClientHandler? = nil
    
    public static var shared: ZenSMTP!
        
    public init(config: ServerConfiguration, eventLoopGroup: EventLoopGroup) throws {
        self.eventLoopGroup = eventLoopGroup
        self.config = config
        if let cert = config.cert, let key = config.key {
            let configuration = TLSConfiguration.forServer(
                certificateChain: [cert],
                privateKey: key)
            let sslContext = try NIOSSLContext(configuration: configuration)
            clientHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: config.hostname)
        }
        ZenSMTP.shared = self
    }

    let communicationHandler: (String) -> Void = { str in
        print(str)
    }
    
    public func send(email: Email) -> EventLoopFuture<Void> {
        let emailSentPromise: EventLoopPromise<Void> = eventLoopGroup.next().makePromise()
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                #if DEBUG
                _ = channel.pipeline.addHandler(PrintEverythingHandler(handler: self.communicationHandler))
                #endif
                return channel.pipeline.addHandlers([
                    ByteToMessageHandler(LineBasedFrameDecoder()),
                    SMTPResponseDecoder(),
                    MessageToByteHandler(SMTPRequestEncoder()),
                    SendEmailHandler(configuration: self.config,
                                     email: email,
                                     allDonePromise: emailSentPromise)
                    ], position: .last)
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
        guard let clientHandler = ZenSMTP.shared.clientHandler else {
            return self
        }
        
        return self.channelInitializer { channel in
            channel.pipeline.addHandler(clientHandler)
        }
    }
}

