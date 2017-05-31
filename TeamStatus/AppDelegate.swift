//
//  AppDelegate.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var statusMenu: NSMenu!

	let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

	@IBAction func quitClicked(_ sender: Any) {
		NSApplication.shared().terminate(self)
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		//statusItem.title = "TeamStatus"
		//statusItem.menu = statusMenu

		let icon = NSImage(named: "statusIcon")
		icon?.isTemplate = true // best for dark mode
		statusItem.image = icon
		statusItem.menu = statusMenu
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

