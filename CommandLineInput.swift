//
//  CommandLineInput.swift
//  TeamStatus
//
//  Created by Marcin Religa on 04/11/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

struct CommandLineInput {
	let repositoryURL: URL
	let token: String

	init?() {
		guard CommandLine.arguments.count >= 3 else {
			Logger.log("Invalid input params.")
			return nil
		}

		guard
			let repositoryURL = URL(string: CommandLine.arguments[1])
		else {
			Logger.log("First argument needs to be the URL for the git repository.")
			return nil
		}

		self.repositoryURL = repositoryURL
		token = CommandLine.arguments[2]
	}
}
