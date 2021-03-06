//
//  VersionUtilities.swift
//  NStack
//
//  Created by Kasper Welner on 20/10/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import Foundation

enum VersionUtilities {
    
    internal static var versionOverride: String?

    static var previousAppVersion: String {
        get {
            let savedVersion = Constants.persistentStore.object(forKey: Constants.CacheKeys.previousVersion) as? String
            return savedVersion ?? currentAppVersion
        }

        set {
            Constants.persistentStore.setObject(newValue, forKey: Constants.CacheKeys.previousVersion)
        }
    }

    static var currentAppVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
    
    static func isVersion(_ versionA:String, greaterThanVersion versionB:String) -> Bool {
        
        var versionAArray = versionA.components(separatedBy: ".")
        var versionBArray = versionB.components(separatedBy: ".")
        let maxCharCount = max(versionAArray.count, versionBArray.count)
        
        versionAArray = normalizedValuesFromArray(versionAArray, maxValues: maxCharCount)
        versionBArray = normalizedValuesFromArray(versionBArray, maxValues: maxCharCount)
        
        for i in 0..<maxCharCount {
            if  versionAArray[i] > versionBArray[i] {
                return true
            } else if versionAArray[i] < versionBArray[i] {
                return false
            }
        }

        return false
    }

    static func normalizedValuesFromArray(_ array: [String], maxValues: Int) -> [String] {
        guard array.count < maxValues else {
            return array
        }

        return array + [String](repeating: "0", count: maxValues - array.count)
    }
}
