//
//  MediaViewerWindowController.swift
//  MediaLibraryManager
//
//  Created by Nikolah Pearce and Vivian Breda on 23/09/18.
//  Copyright © 2018 Nikolah Pearce and Vivian Breda. All rights reserved.
//

import Cocoa

/**
Window for the viewing of media content.
Has a custom view that changes view controllers depending upon file type.
*/
class MediaViewerWindowController: NSWindowController {
    
    @IBOutlet weak var customView: NSView!
    @IBOutlet var viewerWindow: NSWindow!
    @IBOutlet weak var editDetails: NSSegmentedControl!
    @IBOutlet weak var detailsView: NSTableView!
    
    @IBOutlet var notesTextView: NSTextView!
    @IBOutlet weak var editNotesButton: NSView!
    @IBOutlet weak var saveNotesButton: NSButton!
    
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    var fileToOpen: MMFile = File(filename: "MLM - Media Viewer")
    var allFiles: [MMFile] = []
    var currentFileIndex : Int = -1
	var bookmark: String = ""
	
	/**
	Convenience initialiser that loads the NIB file.
	*/
	convenience init() {
		self.init(windowNibName: NSNib.Name(rawValue: "MediaViewerWindowController"));
	}
    
    /**
	Convenience initialiser that loads the NIB file.
	Initialises the new controller with a specific file as the start point.
	*/
    convenience init(index: Int, files: [MMFile]) {
        self.init(windowNibName: NSNib.Name(rawValue: "MediaViewerWindowController"));
        allFiles = files
        currentFileIndex = index
        fileToOpen = allFiles[currentFileIndex]
    }
	
	/**
	Called when the Window loaded successfully.
	Sets the delegates, and disables some buttons.
	Also sets the Custom View to the correct controller by calling helper method.
	*/
    override func windowDidLoad() {
        super.windowDidLoad()
        detailsView.delegate = self
        detailsView.dataSource = self
		notesTextView.isEditable = false
		setCorrectController()
    }
    
    /**
    Called when the Window is closed.
    Sets customView to its default state when the viewer window is closed.
    */
    func windowWillClose(_ notification: Notification) {
        setCorrectController()
    }
    
    /**
    Helper method to add a metadata keypair.
    Allows the menu item to use the +- buttons.
    Adds a new metadata keypair to the open file.
    */
	@IBAction func addMetadataShortcut(_ sender: Any) {
		var commandInput : String = ""
		let selectedFile : Int = currentFileIndex
		LibraryMainWindow.model.last = MMResultSet(allFiles)
		
		let detailToAdd = getString(title: "Add New Detail to \(fileToOpen.filename):", question: "Please enter a new key-value information. You cannot use a keyword that already exists", defaultValue: "Ex: color purple")
		if (detailToAdd != nil) {
			commandInput = "add \(selectedFile) \(detailToAdd!)"
			LibraryMainWindow.model.runCommand(input: commandInput)
		}
        fileViewingDidChange()
	}
	
    /**
    Handles adding and deleting metadata from a file.
    Utilises + - buttons to control add / delete respectively.
    Prompts the user with a text field when needed.
    Also alerts the user with any errors caused by their actions e.g. entering invalid metadata or deleting a required metadata.
     */
    @IBAction func editDetailsAction(_ sender: Any) {
        var commandInput : String = ""
        let selectedFile : Int = currentFileIndex
        
        // Set the last result set to be current bookmark - in case it wasn't already
        LibraryMainWindow.model.last = MMResultSet(allFiles)
        
        if (editDetails.isSelected(forSegment: 0)) {
			addMetadataShortcut(self)
        } else if (editDetails.isSelected(forSegment: 1)) {
            let row = detailsView.selectedRow
			guard row >= 0 && row < fileToOpen.metadata.count else {
				return
			}
			// Check that it's allowed
			let key = fileToOpen.metadata[row].keyword
			do {
				let isAllowed = try FileValidator.safeToDelete(key: key, typeOfFile: fileToOpen.type)
				if isAllowed {
					commandInput = "del \(selectedFile) \(key)"
					LibraryMainWindow.model.runCommand(input: commandInput)
				}
			} catch {
				alertUserOfFailure(methodThatFailed: "Deleting Metadata", maintext: "Cannot delete a required metadata keypair for the file type.")
			}
        }
		fileViewingDidChange()
    }
    
    /**
     Button action for allowing the notes text field to be editable.
     Changes the is editable attribute of the notes.
    */
    @IBAction func editNotesButtonAction(_ sender: Any) {
		notesTextView.isEditable = true
    }
    
    /**
     Button action for allowing the notes text to be saved to the file.
     Also changes the is editable attribute of the notes to be false.
     */
    @IBAction func saveNotesButtonAction(_ sender: Any) {
		let text = notesTextView.string
		LibraryMainWindow.model.library.addNotesToFile(notes: text, file: allFiles[currentFileIndex])
        LibraryMainWindow.model.alertLibraryDelegate()
		notesTextView.isEditable = false
    }
    
    /**
     Button action for moving to the previous media.
     Changes the file index that is being viewed.
     Reloads the custom view in case file type changed.
     */
    @IBAction func previousButtonAction(_ sender: Any) {
		guard currentFileIndex >= 1 else {
			return
		}
		currentFileIndex -= 1
		setCorrectController()
		fileViewingDidChange()
    }
    
    /**
     Button action for moving to the next media.
     Changes the file index that is being viewed.
     Reloads the custom view in case file type changed.
     */
    @IBAction func nextButtonAction(_ sender: Any) {
		guard currentFileIndex < allFiles.count else {
			return
		}
		currentFileIndex += 1
		setCorrectController()
		fileViewingDidChange()
    }
    
    /**
	Based upon the file type, set the current View Controller.
	The default creates an image controller, but this will never be called as all file types are validated.
	*/
	func setCorrectController() {
		fileToOpen = allFiles[currentFileIndex]
		self.customView.subviews.removeAll()
		var myView : NSViewController
        switch (fileToOpen.type.capitalized) {
            case "Document" :
                myView = DocumentViewController(file: fileToOpen)
			case "Image" :
                myView = ImageViewController(file: fileToOpen)
            case "Video", "Audio" :
                myView = AVViewController(file: fileToOpen)
            default:
				myView = ImageViewController(file: fileToOpen)
                print("")
        }
		myView.view.setFrameOrigin(NSPoint(x:0, y:0))
		myView.view.setFrameSize(customView.frame.size)
		customView.addSubview(myView.view)

		viewerWindow.title = "\(fileToOpen.filename)"
        fileViewingDidChange()
	}
	
	/**
	Prompt the user to enter some text e.g. the new metadata key pair.
	- parameter title: the title of the Alert prompt.
	- parameter question: the full text question to inform user.
	- parameter defaultValue: the placeholder string to put in the text field.
	- returns: String?: the metadata keypair entered by the user or nil.
	
	@author Marc Fearby on Stack Overflow, + minor changes by Vivian.
	*/
    func getString(title: String, question: String, defaultValue: String) -> String? {
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
        msg.messageText = title
        msg.informativeText = question
        
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.placeholderString = defaultValue
        
        msg.accessoryView = txt
        let response: NSApplication.ModalResponse = msg.runModal()
        
        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
			guard txt.stringValue.count >= 3 else {
				alertUserOfFailure(methodThatFailed: "Adding Metadata", maintext: "Please enter a key followed by a space and then your value. Extra spaces will be ignored.")
				return nil
			}
			let parts = txt.stringValue.split(separator: " ").map({String($0)})
			guard parts.count >= 2 else {
				alertUserOfFailure(methodThatFailed: "Adding Metadata", maintext: "Please enter a key followed by a space and then your value. Extra spaces will be ignored.")
				return nil
			}
            return txt.stringValue
        } else {
            return nil
        }
    }
	
	/**
	Prompts the user with an alert to warn them their metadata deletion failed
	- parameter bookmark:  the name of the bookmark to check.
	*/
	func alertUserOfFailure(methodThatFailed: String, maintext: String) {
		let msg = NSAlert()
		msg.addButton(withTitle: "OK")
		var title = "Error: "
		title += methodThatFailed
		title += " Failure."
		msg.messageText = title
		msg.informativeText = maintext
		let _: NSApplication.ModalResponse = msg.runModal()
		return
	}
    /**
     Disables and enables the buttons based upon whats selected being viewed
     */
    func manageButtons() {
		if currentFileIndex == 0 {
			previousButton.isEnabled = false
		} else {
			previousButton.isEnabled = true
		}
		
		if currentFileIndex == (allFiles.count-1) {
			nextButton.isEnabled = false
		} else {
			nextButton.isEnabled = true
		}
    }
    
    /**
     Updates the label at bottom of table.
     Shows the total items and those selected.
     */
    func updateStatus() {
        var text = "Viewing item "
        text += String(currentFileIndex+1)
        text += " of "
        text += String(allFiles.count)
        statusLabel.stringValue = text
    }
	
	/**
	Helper function that is called whenever the file within the Custom View changes.
	Calls the other helped methods to ensure everything is updated.
	Including, the buttons, the label, the metadata and the notes.
	*/
    func fileViewingDidChange() {
        detailsView.reloadData()
        notesTextView.string = allFiles[currentFileIndex].notes
        manageButtons()
        updateStatus()
    }
}

/**
Extension that confirms to the NSTableViewDataSource.
Allows us to define the number of rows in our table.
*/
extension MediaViewerWindowController : NSTableViewDataSource {
	
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileToOpen.metadata.count
    }
	
}

/**
Extension that confirms to the NSWindowDelegate.
Allows us to define the number of rows in our table.
*/
extension MediaViewerWindowController : NSWindowDelegate {

	func windowDidResize(_ notification: Notification) {
		setCorrectController()
	}
}

/**
Extension that conforms to the NSTableViewDelegate.
Allows the table data to be filled.
*/
extension MediaViewerWindowController : NSTableViewDelegate {

	/**
	Enum to store the Cell Identifiers of the table.
	*/
    fileprivate enum CellIdentifiers {
        static let KeywordCell = "CellKeywordID"
        static let ValueCell = "CellValueID"
    }
	
	/**
	Called when the table needs to reload data.
	*/
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text: String = ""
        var cellIdentifier: String = ""

        let item = allFiles[currentFileIndex].metadata[row]

        if tableColumn == detailsView.tableColumns[0] {
            text = item.keyword.capitalized
            cellIdentifier = CellIdentifiers.KeywordCell
        } else if tableColumn == detailsView.tableColumns[1] {
            text = item.value
            cellIdentifier = CellIdentifiers.ValueCell
        }

       if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

	/**
	In built delegate method that is called whenever the selection within the table changes.
	*/
    func tableViewSelectionDidChange(_ notification: Notification) {

    }
}

