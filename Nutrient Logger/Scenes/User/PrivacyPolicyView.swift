//
//  PrivacyPolicyView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 9/24/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("PRIVACY POLICY")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                Text("""
    Nutrient Logger does not require an account or sign-in, and does not operate any server that your food log is sent to or stored on. Everything you log - foods, meals, weight, goals - is stored locally in the app's data store on your device.

    We do not sell your personal information, and we do not share what you eat, your weight, or any other data you enter with advertisers or other third parties.

    Here is what does leave your device, and why:

    (1) Anonymous product analytics (Firebase Analytics). We log which screens and features are used - for example, that a food was logged, a barcode was scanned, or a premium feature was tapped - so we know what to improve. These events do not include the name of any food you ate, your weight, or other personal details, and are not linked to your identity.

    (2) Barcode lookups (Open Food Facts). When you scan a packaged food's barcode, the barcode number is sent to the Open Food Facts public database to retrieve its nutrition information. No other information about you is sent with that request.

    (3) Apple Health, only if you turn it on. If you enable Health sync, your calorie, macro, and water data is written to Apple Health, and weight data can be imported from Health. This stays within Apple's Health system on your device and is governed by Apple's own Health privacy protections, not sent to us.

    Nutrient Logger does not show ads. Free-tier users occasionally see a prompt suggesting Premium in a handful of screens throughout the app. It's not served by any ad network, and no information about you is sent anywhere to show it.

    You can request details about what analytics data has been collected, or ask us to stop collecting it, by contacting us via the feedback option in the app.

    If you believe at any point that we are not following this privacy policy as stated, please contact us via the feedback option in the app.
    """
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PrivacyPolicyView()
}
