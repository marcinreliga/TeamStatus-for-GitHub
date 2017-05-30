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
	private let remoteStorageURL: URL

	init(remoteStorageURL: URL) {
		self.remoteStorageURL = remoteStorageURL
	}

	func query(_ query: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
		let semaphore = DispatchSemaphore(value: 0)

		var request = URLRequest(url: remoteStorageURL)
		request.httpMethod = "POST"

		request.addValue(" bearer 5f7f4b7cdf3b22e63b7e18a42acb2c5086101ffa", forHTTPHeaderField: "Authorization")
		//var data: [String: Any] = [:]


		//let postString = formatPOSTString(data: data)
		request.httpBody = query.data(using: .utf8)
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				completion(.failure(NetworkError.didFailToFetchData))
				return
			}

			completion(.success(data))
			semaphore.signal()
		}
		task.resume()
		semaphore.wait();
	}

//	private func formatPOSTString(data: [String: Any]) -> String {
//		var resultArr: [String] = []
//
//		for (key, value) in data {
//			resultArr.append("\"\(key)\": \"\(value)\"")
//		}
//
//		return "{ " + resultArr.joined(separator: ", ") + " }"
//	}
}
