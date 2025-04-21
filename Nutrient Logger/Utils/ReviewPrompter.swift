//
//  ReviewPrompter.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/20/25.
//

import Foundation
import SwiftUI
import MessageUI
import StoreKit

class ReviewPrompter: NSObject, ObservableObject, MFMailComposeViewControllerDelegate {
    
    @AppStorage("lastReviewPromptDate") var lastReviewPromptDate: Date?
    @AppStorage("stopPromptingForReviews") var stopPromptingForReviews: Bool = false
    
    @Published var showAreYouEnjoyingAlert: Bool = false
    @Published var showReviewPrompt: Bool = false
    @Published var showFeedbackPrompt: Bool = false
    @Published var showEmailDoesntWorkAlert: Bool = false
    @Published var areYouEnjoyingPrompt: String = ""
    
    let feedbackRecipient = "jasonsappsfeedback@gmail.com"

    let wouldYouPleaseReview = "Would you please take a few moments to leave us a review?"
    let sorryYoureNotEnjoying = "Sorry your experience has not been enjoyable. Please let us know how we can improve."
    let emailDoesntWork = "Email is not set up on this device."

    let appName: String
    
    var canLeaveFeedback: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    override init() {
        appName = "\(Bundle.main.appName) \(Bundle.main.version)(\(Bundle.main.buildNumber))"
    }
    
    private func resetForTesting() {
        lastReviewPromptDate = .distantPast
        stopPromptingForReviews = false
    }
    
    public func promptUserForReview(areYouEnjoyingPrompt: String = "Are you enjoying the app?") {
        self.areYouEnjoyingPrompt = areYouEnjoyingPrompt

        if (shouldNotPromptForReview()) {
            return
        }

        lastReviewPromptDate = .now
        showAreYouEnjoyingAlert = true
    }
    
    private func shouldNotPromptForReview() -> Bool {
        if stopPromptingForReviews {
            return true
        }
        
        let interval = abs(Date.now.distance(to: lastReviewPromptDate ?? .distantPast))
        return interval < TimeInterval.fromDays(1)
    }
    
    func onUserEnjoyingApp() {
        showReviewPrompt = true
    }

    func onUserNotEnjoyingApp() {
        showFeedbackPrompt = true
    }
    
    @MainActor
    func onUserChoseToReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive } ) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
        stopPromptingForReviews = true
    }

    func onUserChoseNoMoreReviewRequests() {
        stopPromptingForReviews = true
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
            tellUserThatTheirEmailDoesntWork()
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive } ) as? UIWindowScene {
            scene.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
        }
        if (result == MFMailComposeResult.sent) {
            stopPromptingForReviews = true
        }
    }
    
    private func tellUserThatTheirEmailDoesntWork() {
        showEmailDoesntWorkAlert = true
    }
}

extension View {
    
    func reviewPromptAlert(prompter: ReviewPrompter) -> some View {
        self
            .alert(
                prompter.areYouEnjoyingPrompt,
                isPresented: .init(get: { prompter.showAreYouEnjoyingAlert }, set: { prompter.showAreYouEnjoyingAlert = $0 })
            ) {
                Button("No") { prompter.onUserNotEnjoyingApp() }
                Button("Yes") { prompter.onUserEnjoyingApp() }
            }
            .alert(
                prompter.wouldYouPleaseReview,
                isPresented: .init(get: { prompter.showReviewPrompt }, set: { prompter.showReviewPrompt = $0 })
            ) {
                Button("Don't ask again") { prompter.onUserChoseNoMoreReviewRequests() }
                Button("Ok") { prompter.onUserChoseToReview() }
            }
            .alert(
                prompter.sorryYoureNotEnjoying,
                isPresented: .init(get: { prompter.showFeedbackPrompt }, set: { prompter.showFeedbackPrompt = $0 })
            ) {
                Button("Don't ask again") { prompter.onUserChoseNoMoreReviewRequests() }
                Button("Ok") { prompter.leaveFeedback() }
            }
            .alert(
                prompter.emailDoesntWork,
                isPresented: .init(get: { prompter.showEmailDoesntWorkAlert }, set: { prompter.showEmailDoesntWorkAlert = $0 })
            ) { }
    }
}
