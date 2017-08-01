//
//  NSImageView+URL.swift
//  TeamStatus
//
//  Created by Marcin Religa on 01/08/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

extension NSImageView {
	public func loadImageFromURL(urlString: String) {
		URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { data, response, error in
			if let error = error {
				Logger.log(error.localizedDescription)
				return
			}
			
			DispatchQueue.main.async {
				self.image = NSImage(data: data!)
			}
		}).resume()
	}
}
