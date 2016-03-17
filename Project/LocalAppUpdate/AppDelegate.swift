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

  var	queue	=	dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  let	onEvents	=	{ (events:[FileSystemEvent]) -> () in
    for ev in events {
      print("Event: \(ev)")
    }
  }
  var	monitor	=	nil as FileSystemEventMonitor?
  
  var watchForChanges:Bool {
    set {
      if newValue == true {
        let path = "/Users/boyvanamstel/Desktop/testing"
        self.monitor = FileSystemEventMonitor(pathsToWatch: [path], latency: 0, watchRoot: false, queue: self.queue, callback:self.onEvents)
      } else {
        self.monitor = nil
      }
    }
    get {
      return self.monitor != nil
    }
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    

  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

}

