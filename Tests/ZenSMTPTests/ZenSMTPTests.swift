import XCTest
import Foundation
@testable import ZenSMTP

final class ZenSMTPTests: XCTestCase {
    
    func testSendEmail() {
        var response: Bool = false
        
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
            hostname: "pro.eu.turbo-smtp.com",
            port: 25,
            username: "g.grisolini@bluecityspa.com",
            password: "Sm0CPGnB",
            cert: nil, //.file("/Users/gerardo/Projects/ZenNIO/SSL/cert.pem"),
            key: nil //.file("/Users/gerardo/Projects/ZenNIO/SSL/key.pem")
        )
        
        let smtp = ZenSMTP(config: config)
        
        smtp.send(email: email) { error in
            if let error = error {
                print("❌ : \(error)")
            } else {
                response = true
                print("✅")
            }
        }
        
        let exp = expectation(description: "Test send email for 10 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 10.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertTrue(response)
        } else {
            XCTFail("Test interrupted")
        }
    }
    
    static var allTests = [
        ("testSendEmail", testSendEmail),
    ]
}
