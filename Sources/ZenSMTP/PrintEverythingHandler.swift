//
//  PrintEverythingHandler.swift
//  ZenSMTP
//
//  Created by admin on 01/03/2019.
//

import Foundation
import NIO
import Logging

final class PrintEverythingHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        logger.trace(Logger.Message(stringLiteral: "☁️ \(String(decoding: buffer.readableBytesView, as: UTF8.self))"))
        context.fireChannelRead(data)
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = self.unwrapOutboundIn(data)
        if buffer.readableBytesView.starts(with: Data(ZenSMTP.mail.config.password.utf8).base64EncodedData()) {
            logger.trace(Logger.Message(stringLiteral: "📱 <password hidden>\r\n"))
        } else {
            logger.trace(Logger.Message(stringLiteral: "📱 \(String(decoding: buffer.readableBytesView, as: UTF8.self))"))
        }
        context.write(data, promise: promise)
    }
}
