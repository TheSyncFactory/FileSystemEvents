//
//  AppDelegate.swift
//  LocalAppUpdate
//
//  Created by Boy van Amstel on 17/03/16.
//  Copyright © 2016 Eonil. All rights reserved.
//

import Cocoa
import EonilFileSystemEvents

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var sourceButton: NSButton!
  @IBOutlet weak var sourceField: NSTextField!
  @IBOutlet weak var destinationButton: NSButton!
  @IBOutlet weak var destinationField: NSTextField!

  var sourcePath:String {
    set {
      self.sourceField.stringValue = newValue
      NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "LAUSourcePath")
    }
    get {
      return self.sourceField.stringValue
      
    }
  }
  var destinationPath:String {
    set {
      self.destinationField.stringValue = newValue
      NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "LAUDestinationPath")
    }
    get {
      return self.destinationField.stringValue
    }
  }
  
  var	queue	=	dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  var	monitor	=	nil as FileSystemEventMonitor?
 
  var watchForChanges:Bool {
    set {
      if newValue == true {
        startMonitoring()
      } else {
        stopMonitoring()
      }
    }
    get {
      return self.monitor != nil
    }
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    
    if let sP = NSUserDefaults.standardUserDefaults().valueForKey("LAUSourcePath") {
      if NSFileManager.defaultManager().fileExistsAtPath(sP as! String) {
        self.sourcePath = sP as! String
      }
    }
    if let dP = NSUserDefaults.standardUserDefaults().valueForKey("LAUDestinationPath") {
      if NSFileManager.defaultManager().fileExistsAtPath(dP as! String) {
        self.destinationPath = dP as! String
      }
    }
  }
  
  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }
  
  func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
    return true
  }
  
  func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
    
    if notification.activationType == NSUserNotificationActivationType.ActionButtonClicked {
      if let zipPath = notification.userInfo!["zipPath"] {
        print("Will kill app and run replace with \(zipPath)")
        if killApp(self.destinationPath) {
          if removeOld(self.destinationPath) {
            let destinationFolderPath = NSURL.fileURLWithPath(self.destinationPath).URLByDeletingLastPathComponent!.path
            if extractZip(zipPath as? String, toPath: destinationFolderPath) {
              if runUpdate(self.destinationPath) {
                print("Update has been installed")
              }
            }
          }
        }
      }
    }
  }
  
  func onEvents(events: [FileSystemEvent]) {
    for ev in events {
      let sourceURL = NSURL.fileURLWithPath(ev.path)
      if sourceURL.pathExtension == "zip" {
        if ev.flag.contains(FileSystemEventFlag.ItemCreated) {
          // Ask what to do
          let notification = NSUserNotification()
          notification.title = "Local update available"
          notification.informativeText = "Do you want to quit the current app and run the update?"
          notification.actionButtonTitle = "Update"
          notification.userInfo = ["zipPath": sourceURL.path!]
          NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification)
        }
      }
    }
  }
  
  func killApp(appPath: String?) -> Bool {
    if let path = appPath {
      // Check if app is running
      if let bundle = NSBundle(path: path) {
        print("Found bundle: \(bundle)")
        if let identifier = bundle.bundleIdentifier {
          let apps = NSRunningApplication.runningApplicationsWithBundleIdentifier(identifier)
          print("Running apps: \(apps)")
          for runningApp in apps {
            // Kill if it's the app running at the destination path
            if runningApp.bundleURL!.path == appPath {
              print("Terminating \(appPath)")
              return runningApp.terminate()
            }
          }
        }
        return true
      }
    }
    return false
  }
  
  func removeOld(appPath: String?) -> Bool {
    if let path = appPath {
      if NSFileManager.defaultManager().fileExistsAtPath(path) {
        do {
          try NSFileManager.defaultManager().trashItemAtURL(NSURL.fileURLWithPath(path), resultingItemURL: nil)
          return true
        } catch let error as NSError {
          print("Failed to remove item at \(path): \(error)")
        }
      } else {
        return true
      }
    }
    return false
  }
  
  func extractZip(fromPath: String?, toPath: String?) -> Bool {
    if let from = fromPath {
      if let to = toPath {
        print("Extract from \(from) to \(to)")
        let task = NSTask()
        task.launchPath = "/usr/bin/unzip"
        task.arguments = ["-qou", from, "-d", to]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == EXIT_SUCCESS
      }
    }
    return false
  }
  
  func runUpdate(destinationPath: String?) -> Bool {
    if let path = destinationPath {
      print("Run at \(path)")
      do {
        try NSWorkspace.sharedWorkspace().launchApplicationAtURL(NSURL.fileURLWithPath(path), options: NSWorkspaceLaunchOptions.Default, configuration: [NSWorkspaceLaunchConfigurationArguments: []])
      } catch let error as NSError {
        print("Failed to launch application at \(path): \(error)")
      }
      return true
    }
    return false
  }
  
  func startMonitoring() -> Bool {
    stopMonitoring()
    
    let path = self.sourcePath
    if path.characters.count > 0 {
      self.monitor = FileSystemEventMonitor(pathsToWatch: [path], latency: 0, watchRoot: false, queue: self.queue, callback:onEvents)
      if self.monitor != nil {
        return true
      }
    }
    return false
  }
  func stopMonitoring() {
    self.monitor = nil
  }
  
  @IBAction func browse(sender: NSButton) {
    
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    if sender == self.sourceButton {
      openPanel.canChooseDirectories = true
      openPanel.canChooseFiles = false
    } else if (sender == self.destinationButton) {
      openPanel.canChooseDirectories = false
      openPanel.canChooseFiles = true
      openPanel.allowedFileTypes = ["app"]
    }
    openPanel.beginSheetModalForWindow(self.window, completionHandler: { (result) -> Void in
      if result == NSFileHandlingPanelOKButton {
        
        if sender == self.sourceButton {
         
          if let URL = openPanel.URL {
            self.sourcePath = URL.path!
          }
        } else if (sender == self.destinationButton) {
          
          if let URL = openPanel.URL {
            self.destinationPath = URL.path!
          }
        }
      }
    })
  }
  
  @IBAction func switchMonitoring(sender: NSButton) {
    
    if self.watchForChanges {
      self.stopMonitoring()
      sender.state = 0
    } else {
      if self.startMonitoring() {
        sender.state = 1
      } else {
        sender.state = 0
      }
    }
  }
}

