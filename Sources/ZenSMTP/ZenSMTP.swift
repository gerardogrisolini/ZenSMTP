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
    
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var eventLoop: EventLoop {
        return self.eventLoopGroup.next()
    }
    public var config: ServerConfiguration!
    public var clientHandler: NIOSSLClientHandler? = nil
    
    public static var shared: ZenSMTP!
    
    public init(config: ServerConfiguration) throws {
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
    
    public func send(email: Email, handler: @escaping (String?) -> ()) {
        let emailSentPromise: EventLoopPromise<Void> = eventLoop.makePromise()
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    PrintEverythingHandler(handler: self.communicationHandler),
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
    
    public func close() throws {
        try eventLoopGroup.syncShutdownGracefully()
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
