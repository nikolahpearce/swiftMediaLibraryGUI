//
//  Media.swift
//  MediaLibraryManager
//
//  Created by Nikolah Pearce and Vivian Breda on 13/08/18.
//  Copyright © 2018 Paul Crane. All rights reserved.
//

import Foundation

extension MMFile {
    
    static func == (lhs: Self, rhs: MMFile) -> Bool {
        return lhs.filename == rhs.filename && lhs.path == rhs.path
    }
    
    static func != (lhs: Self, rhs: MMFile) -> Bool{
        return !(lhs == rhs)
    }
    
    var type: String {
        var keys: [String] = []
        for m in metadata {
            keys.append(m.keyword)
        }
        if keys.contains("resolution") && keys.contains("runtime") {
            return "video"
        } else if keys.contains("resolution") {
            return "image"
        } else if keys.contains("runtime") {
            return "audio"
        } else {
            return "document"
        }
    }
    
}

/**
  Creates a media file with metadata.
 */
class File: MMFile {
  
    
    // STORED PROPERTIES
    private var _fMetadata : [MMMetadata] = []
    private var _fFilename = String()
    private var _fPath = String()
    private var _fCreator = String()
    private var _fNotes = String()
    
    var fullpath: String = ""
    
	init() {
	}
	
	init(filename: String) {
		self._fFilename = filename
	}
	
    /**
      Designated initialiser
     
      The properties of the file.
     
      - parameter metadata: all the metadata of a file.
      - parameter filename: the name of the file.
      - parameter path: the File's path.
      - parameter creator: the File's creator.
     */
    init(metadata: [MMMetadata], filename: String, path: String, creator: String) {
        self._fMetadata = metadata
        self._fFilename = filename
        self._fPath = path
        self._fCreator = creator
		self._fNotes = ""
		addAdditionalMetadata()
    }
	
	/**
	Designated initialiser
	
	The properties of the file.
	
	- parameter metadata: all the metadata of a file.
	- parameter filename: the name of the file.
	- parameter path: the File's path.
	- parameter creator: the File's creator.
	- parameter notes: the notes to load file with.
	*/
	init(metadata: [MMMetadata], filename: String, path: String, creator: String, notes: String) {
		self._fMetadata = metadata
		self._fFilename = filename
		self._fPath = path
		self._fCreator = creator
		self._fNotes = notes
		addAdditionalMetadata()
	}
	
	/**
	Adds some additional metadata to the file.
	Allows more of the state to be written to disk when closed.
	*/
	func addAdditionalMetadata() {
		
		var keys : [String] = []
		for md in self._fMetadata {
			keys.append(md.keyword)
		}
		
		let str1 = "filename"
		let str2 = "fullpath"
		let str4 = "name"
		
		if !keys.contains(str1) {
			let m: MMMetadata = Metadata(keyword: str1, value: filename)
			self._fMetadata.append(m)
		}

		if !keys.contains(str2) {
			var fullpath : String = path
			fullpath += "/\(filename)"
			let m2: MMMetadata = Metadata(keyword: str2, value: fullpath)
			self._fMetadata.append(m2)
		}
		
		if !keys.contains(str4) {
			let fileWithoutExtension: [String] = filename.split(separator: ".").map({String($0)})
			let m4: MMMetadata = Metadata(keyword: str4, value: fileWithoutExtension[0])
			self._fMetadata.append(m4)
		}
		
		//fullpath = "\(path)\(filename)"
	}
    // The collection of the file's metadata.
    var metadata: [MMMetadata] {
        get {
            return self._fMetadata
        }
        set (newMetadata) {
            self._fMetadata = newMetadata
        }
    }
    
     // The name of the file.
    var filename: String {
        get {
            return self._fFilename
        }
        set (newFilename) {
            self._fFilename = newFilename
        }
    }
    
    // The path to the file.
    var path: String {
        get {
            return self._fPath
        }
        set (newPath) {
            self._fPath = newPath
        }
    }
    
    // The creator of the file.
    var creator: String {
        get {
            return self._fCreator
        }
        set {
            for m in metadata {
                if m.keyword.lowercased() == "creator" {
                    self._fCreator = m.value
                }
            }
        }
    }
    
    // The notes associated with the file
    var notes: String {
        get {
            return self._fNotes
        }
        set (newNotes) {
            self._fNotes = newNotes
        }
    }
    
    /**
      String representation of the file
     
      - returns: String: String representation of the File.
     */
    var description: String {
        return "\(filename)"
    }

}
