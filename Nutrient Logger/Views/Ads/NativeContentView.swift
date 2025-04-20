//
//  Copyright 2022 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import GoogleMobileAds
import SwiftUI

struct NativeContentView: View {

    @StateObject private var nativeViewModel = NativeAdViewModel()

    let navigationTitle: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NativeAdViewContainer(
                    nativeViewModel: nativeViewModel,
                    xibName: "ExampleNativeAdView"
                )
                .frame(minHeight: 300)  // minHeight determined from xib.
                
                Text(
                    nativeViewModel.nativeAd?.mediaContent.hasVideoContent == true
                    ? "Ad contains a video asset." : "Ad does not contain a video."
                )
                .frame(maxWidth: .infinity)
                .foregroundColor(.gray)
                .opacity(nativeViewModel.nativeAd == nil ? 0 : 1)
                
                Button("Refresh Ad") {
                    refreshAd()
                }
                
                Text(
                    "SDK Version:"
                    + "\(string(for: MobileAds.shared.versionNumber))")
            }
            .padding()
        }
        .onAppear {
            refreshAd()
        }
        .navigationTitle(navigationTitle)
    }
    
    private func refreshAd() {
        nativeViewModel.refreshAd()
    }
}

struct NativeContentView_Previews: PreviewProvider {
    static var previews: some View {
        NativeContentView(navigationTitle: "Native")
    }
}

struct SimpleNativeAdView: View {
    
    enum Size {
        case small
        case medium
    }
    
    // Single source of truth for the native ad data.
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @State var size: Size
    
    // minHeight determined from xib.
    private var frameMinHeight: CGFloat {
        switch size {
        case .small: return 100
        case .medium: return 380
        }
    }
    
    private var xibName: String {
        switch size {
        case .small: return "SmallNativeAdView"
        case .medium: return "MediumNativeAdView"
        }
    }
    
    var body: some View {
        NativeAdViewContainer(
            nativeViewModel: nativeViewModel,
            xibName: xibName
        )
        .frame(height: nativeViewModel.nativeAd == nil ? 0 : nil)
        .frame(minHeight: nativeViewModel.nativeAd == nil ? nil : frameMinHeight)
        .opacity(nativeViewModel.nativeAd == nil ? 0 : 1)
        .onAppear {
            nativeViewModel.refreshAd()
        }
    }
}

private struct NativeAdViewContainer: UIViewRepresentable {
    typealias UIViewType = NativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    @State var xibName: String
    
    func makeUIView(context: Context) -> NativeAdView {
        Bundle.main.loadNibNamed(
            xibName,
            owner: nil,
            options: nil)?.first as! NativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        // Each UI property is configurable using your native ad.
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body

        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)

        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store

        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        
        // For the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Associate the native ad view with the native ad object. This is required to make the ad
        // clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        
        var image: UIImage? = nil
        if rating >= 5 {
            image = UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            image = UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            image = UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            image = UIImage(named: "stars_3_5")
        }
        return image?.withTintColor(UIColor(.yellow))
    }
}
