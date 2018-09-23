//
//  MediaViewerWindowController.swift
//  MediaLibraryManager
//
//  Created by Nikolah Pearce on 23/09/18.
//  Copyright © 2018 Nikolah Pearce. All rights reserved.
//

import Cocoa

class MediaViewerWindowController: NSWindowController {

	@IBOutlet var viewerWindow: NSWindow!
	
	convenience init() {
		self.init(windowNibName: NSNib.Name(rawValue: "MediaViewerWindowController"));
		
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		
		viewerWindow.title = "View Media - MLM"


        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
