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
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var sourceButton: NSButton!
  @IBOutlet weak var destinationButton: NSButton!

  var	queue	=	dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  let	onEvents	=	{ (events:[FileSystemEvent]) -> () in
    for ev in events {
      print("Event: \(ev)")
    }
  }
  var	monitor	=	nil as FileSystemEventMonitor?
 
  private var _sourceFolder:String = ""
  var sourceFolder:String {
    set {
      _sourceFolder = newValue
      if self.watchForChanges  {
        startMonitoring()
      }
    }
    get {
      return _sourceFolder
    }
  }
  
  var destinationFolder:String = ""
 
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
  
  func startMonitoring() -> Bool {
    stopMonitoring()
    
    let path = self.sourceFolder
    if path.characters.count > 0 {
      self.monitor = FileSystemEventMonitor(pathsToWatch: [path], latency: 0, watchRoot: false, queue: self.queue, callback:self.onEvents)
      if self.monitor != nil {
        return true
      }
    }
    return false
  }
  func stopMonitoring() {
    self.monitor = nil
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    

  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
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

