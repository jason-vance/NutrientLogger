//
//  Application.swift
//  Application
//
//  Created by Jason Vance on 8/8/21.
//

import Foundation

public class AppInfo {
    
    public static var appName: String {
        get {
            Bundle.main.infoDictionary?["CFBundleName"] as! String
        }
    }
    
    public static var versionString: String {
        get {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        }
    }
    
    public static var buildNumberString: String {
        get {
            Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        }
    }
}
