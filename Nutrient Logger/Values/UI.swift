//
//  UI.swift
//  UI
//
//  Created by Jason Vance on 8/8/21.
//

import Foundation
import UIKit


public enum UI {
    public enum CornerRadius {
        public static let listRow = medium
        public static let dialogContainer = large
        
        public static let xlarge = 16.0
        public static let large = 8.0
        public static let medium = 6.0
        public static let small = 4.0
    }
    
    public enum Outline {
        public static let thin = 0.5
    }
    
    public enum FontSize {
        public static let listRowTitle = UIFont.labelFontSize
        public static let listRowSubtitle = UIFont.systemFontSize
        
        public static let dialogTitle: CGFloat = 18
        public static let dialogMessage: CGFloat = 16
    }
}
