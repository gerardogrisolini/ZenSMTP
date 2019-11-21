import XCTest
import Foundation
import NIO
@testable import ZenSMTP

final class ZenSMTPTests: XCTestCase {
    
    func testSendEmail() {
        let data1 = try! Data(contentsOf: URL(string: "https://www.policymed.com/wp-content/uploads/2013/02/6a00e5520572bb8834017d41062de7970c-320wi.png")!)
        let data2 = "Hello from ZenSMTP".data(using: .utf8)!

        let email = Email(
            fromName: "ZenSMTP",
            fromEmail: "info@grisolini.com",
            toName: nil,
            toEmail: "gerardo@grisolini.com",
            subject: "Email test",
            body: "<html><body><h1>Email attachment test</h1></body></html>",
            attachments: [
                Attachment(
                    fileName: "logo.png",
                    contentType: "text/html",
                    data: data1
                ),
                Attachment(
                    fileName: "info.txt",
                    contentType: "text/plain",
                    data: data2
                )
            ]
        )
        
        let config = ServerConfiguration(
            hostname: "smtp.domain.net",
            port: 25,
            username: "username",
            password: "******",
            cert: nil, //.file("/Users/gerardo/Projects/ZenNIO/SSL/cert.pem"),
            key: nil //.file("/Users/gerardo/Projects/ZenNIO/SSL/key.pem")
        )
        
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        ZenSMTP.mail.setup(config: config, eventLoopGroup: eventLoopGroup)
        ZenSMTP.mail.send(email: email).whenComplete { result in
            switch result {
            case .success(_):
                print("✅")
            case .failure(let err):
                print("❌ : \(err)")
            }
        }

        let exp = expectation(description: "Test send email for 5 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 5.0)
        if result != XCTWaiter.Result.timedOut {
            XCTFail("Test interrupted")
        }
        try! eventLoopGroup.syncShutdownGracefully()
   }
    
    static var allTests = [
        ("testSendEmail", testSendEmail),
    ]
}
