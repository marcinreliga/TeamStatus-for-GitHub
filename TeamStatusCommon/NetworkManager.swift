//
//  NetworkManager.swift
//  TeamStatus
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

enum NetworkError: Error {
	case didFailToFetchData
}

final class NetworkManager {
	private let apiBaseURL: URL
	private let token: String

	init(apiBaseURL: URL, token: String) {
		self.apiBaseURL = apiBaseURL
		self.token = token
	}

	func query(_ query: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
		var request = URLRequest(url: apiBaseURL)
		request.httpMethod = "POST"
		request.addValue("bearer \(token)", forHTTPHeaderField: "Authorization")
		request.httpBody = query.data(using: .utf8)

		// FIXME: This is workaround for GitHub API issues.
		// https://platform.github.community/t/executing-a-request-again-results-in-412-precondition-failed/1456/9
		let config = URLSessionConfiguration.default
		config.requestCachePolicy = .reloadIgnoringLocalCacheData
		config.urlCache = nil
		let session = URLSession.init(configuration: config)

		let task = session.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				completion(.failure(NetworkError.didFailToFetchData))
				return
			}

			completion(.success(data))
		}
		task.resume()
	}
}
