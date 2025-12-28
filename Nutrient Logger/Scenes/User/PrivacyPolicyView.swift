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
    We take personal privacy very seriously. As a general rule we not collect your personal information unless you chose to provide that information to us. When you choose to provide us with your personal information, you are giving us your permission to use that information for the stated purposes listed in this privacy policy. If you choose not to provide us with that information, it might limit the features and services that you can use on this website.

    Generally, the information we request will be used to provide a website feature or service to you, such as commenting, support, or providing future content better tailored to your interests. A description of the intended use of that information, how that information is collected, security measures we take to protect that information, and how to grant or revoke consent for collection and use of that information will be fully described the ‘Privacy Notice’ section of this privacy policy.

    Some of the services on this website allow you to send us an email. We will use the information you provide, such as email address or phone number, only to respond to your inquiry. Keep in mind that email transmissions are not encrypted by default, so we suggest you do not send sensitive information such as Social Security numbers, credit card numbers, or bank account information via such contact forms.

    If such information is required, it will be via a web page that clearly states the page and its transmission of information is secure and encrypted. All electronic messages received from visitors are deleted when no longer needed.

    We take the security of your personal information very seriously. We take many precautions to ensure that the information we collect is secure and inaccessible by anyone outside of our organization. These precautions include advanced access controls to limit access to that information to only internal personnel who require access to that information. We also use numerous security technologies to protect all data stored on our servers and related systems. Our security measures are regularly upgraded and tested to ensure they are effective.

    We take the following specific steps to protect your information:

    (1) Use internal access controls so only limited personnel have access to your information.
    (2) Anyone with access to user information is trained on all relevant security and compliance policies.
    (3) Servers that store visitor information are regularly backed up to protect against loss.
    (4) All information is secured through modern security technologies like secure socket layer (SSL), encryption, firewalls, and secure passwords.

    All access safeguards described above are in place to prevent unauthorized access by outsiders to information stored on or transmitted by our systems.

    You can do the following at any time by contacting us via the contact form available on our website:

    (1) Ask for a list of personal information we have about you, if any.
    (2) Request a change, correction, or deletion of your personal information.
    (3) Request that we avoid collecting anything in the future (opt-out).

    If you do not wish to have cookies stored on your machine, you have the option to turn cookies off in your browser. However, keep in mind that turning off cookies may impact how this website functions. Disabling browser cookies will also impact how other websites you visit store browser cookies as well.

    Whenever we collect any sensitive information (such as social security numbers or credit card information), the information is encrypted and securely transmitted. You are able to confirm this by looking for the ‘lock’ icon in the browser address bar, and also confirm that the URL link starts with ‘https.’

    If you believe at any point that we are not following this privacy policy as stated, please contact us immediately via the contact form available on our website.
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
