//
//  AdProvider.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import UIKit

public protocol AdProvider {
    func loadBannerAdIntoContainer(_ screen: UIViewController, _ view: UIView)
}

//TODO: MVP: Uncomment this when appropriate
//public class GoogleAdProvider: AdProvider {
//    public static let testAdUnitId: String = "ca-app-pub-3940256099942544/2934735716"
//    
//    let adUnitId: String
//    
//    private static var started: Bool = false
//    public static func start() {
//        GADMobileAds.sharedInstance().start(completionHandler: nil)
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "c3ee990cec5f1ee2298f9087ca515ab3" ]
//        started = true
//    }
//    
//    init(adUnitId: String) {
//        self.adUnitId = adUnitId
//        
//        if (!GoogleAdProvider.started) {
//            GoogleAdProvider.start()
//        }
//    }
//    
//    public func loadBannerAdIntoContainer(_ screen: UIViewController, _ container: UIView) {
//        let bannerView = createAdaptiveBannerAd(screen, adUnitId)
//        bannerView.translatesAutoresizingMaskIntoConstraints = false
//
//        container.addSubview(bannerView)
//        container.addConstraints([
//            NSLayoutConstraint(item: bannerView, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: bannerView, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: bannerView, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: 0)
//        ])
//        container.setHeight(bannerView.frame.height)
//
//        loadBannerAd(bannerView)
//    }
//    
//    public func createAdaptiveBannerAd(_ screen: UIViewController, _ adUnitId: String) -> GADBannerView {
//        let ad = GADBannerView(adSize: kGADAdSizeBanner)
//        ad.adUnitID = adUnitId
//        ad.rootViewController = screen
//        ad.adSize = getAdaptiveAdSize(screen)
//        return ad
//    }
//    
//    private func getAdaptiveAdSize(_ screen: UIViewController) -> GADAdSize {
//        let frame = screen.view.frame
//        let insets = screen.view.safeAreaInsets
//        let width = frame.width - insets.left - insets.right
//
//        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
//    }
//    
//    public func loadBannerAd(_ adView: GADBannerView) {
//        adView.load(GADRequest())
//    }
//}
