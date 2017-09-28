//
//  AppDelegate.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/09/13.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// The instance of `AssetPlaybackManager` that the app uses for managing playback.
    let assetPlaybackManager = AssetPlaybackManager()
    
    /// The instance of `RemoteCommandManager` that the app uses for managing remote command events.
    var remoteCommandManager: RemoteCommandManager!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initializer the `RemoteCommandManager`.
        remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlaybackManager)
        
        // Always enable playback commands in MPRemoteCommandCenter.
        remoteCommandManager.activatePlaybackCommands(true)
        
        remoteCommandManager.togglePreviousTrackCommand(true)
        remoteCommandManager.toggleNextTrackCommand(true)
        remoteCommandManager.toggleChangePlaybackPositionCommand(true)
        
        
        // Setup AVAudioSession to indicate to the system you how intend to play audio.
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault)
        }
        catch {
            print("An error occured setting the audio session category: \(error)")
        }
        
        // Set the AVAudioSession as active.  This is required so that your application becomes the "Now Playing" app.
        do {
            try audioSession.setActive(true, with: [])
        }
        catch {
            print("An Error occured activating the audio session: \(error)")
        }
        
        
        guard let viewController = window?.rootViewController as? UPViewController else {
            return true
        }
        viewController.assetPlaybackManager = assetPlaybackManager
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        guard let viewController = window?.rootViewController as? UPViewController else { return }
        viewController.savePlayList()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

