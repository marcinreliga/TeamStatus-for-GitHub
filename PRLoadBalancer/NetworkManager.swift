//
//  NetworkManager.swift
//  PRLoadBalancer
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

		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				completion(.failure(NetworkError.didFailToFetchData))
				return
			}

			completion(.success(data))
		}
		task.resume()
	}
}
