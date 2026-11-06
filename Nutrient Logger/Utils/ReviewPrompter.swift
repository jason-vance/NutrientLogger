//
//  ReviewPrompter.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/20/25.
//

import Foundation
import SwiftUI
import MessageUI

/// Opens a feedback email to the developer. The automatic rating prompt lives on the dashboard
/// (see `ReviewRequestTrigger`).
class ReviewPrompter: NSObject, ObservableObject, MFMailComposeViewControllerDelegate {

    @Published var showEmailDoesntWorkAlert: Bool = false

    let feedbackRecipient = "jasonsappsfeedback@gmail.com"
    let emailDoesntWork = "Email is not set up on this device."

    let appName: String

    override init() {
        appName = "\(Bundle.main.appName) \(Bundle.main.version)(\(Bundle.main.buildNumber))"
    }

    func leaveFeedback() {
        if (MFMailComposeViewController.canSendMail()) {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([ feedbackRecipient ])
            mail.setSubject(appName + " iOS Feedback")
            mail.setMessageBody("I think the app would be better if...", isHTML: false)

            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive } ) as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(mail, animated: true, completion: nil)
            }
        } else {
            showEmailDoesntWorkAlert = true
        }
    }

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive } ) as? UIWindowScene {
            scene.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension View {

    /// Tells the user when they tap Support but have no mail account set up.
    func feedbackAlert(prompter: ReviewPrompter) -> some View {
        self.alert(
            prompter.emailDoesntWork,
            isPresented: .init(get: { prompter.showEmailDoesntWorkAlert }, set: { prompter.showEmailDoesntWorkAlert = $0 })
        ) { }
    }
}
