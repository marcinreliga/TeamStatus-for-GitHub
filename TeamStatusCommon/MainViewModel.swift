//
//  MainViewModel.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

protocol MainViewProtocol {
	func didFinishRunning(reviewers: [Engineer], viewer: GraphAPIResponse.Data.Viewer?)
	func didFailToRun()
	func updateStatusItem(title: String, isAttentionNeeded: Bool)
	func updateViewerView(with engineer: Engineer, ownPullRequestsCount: Int, pullRequestsToReviewCount: Int, pullRequestsReviewed: Int)
}

final class MainViewModel {
	private let view: MainViewProtocol
	private let queryManager: QueryManager = QueryManager()
	private let networkManager: NetworkManager

	var reviewersSorted: [Engineer] = []
	private var pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node] = []
	private var viewer: GraphAPIResponse.Data.Viewer?
	private var repositoryURL: URL

	init(view: MainViewProtocol, repositoryURL: URL, token: String) {
		self.view = view
		self.repositoryURL = repositoryURL
		self.networkManager = NetworkManager(apiBaseURL: Configuration.apiBaseURL, token: token)
	}

	func run() {
		guard let query = queryManager.allPullRequestsQuery else {
			return Logger.log("Query is empty.")
		}

		networkManager.query(query) { [weak self] result in
			guard let _self = self else {
				return
			}

			switch result {
			case .success(let data):
				do {
					let graphAPIResponse = try JSONDecoder().decode(GraphAPIResponse.self, from: data)

					let reviewersRequested = graphAPIResponse.data.repository.pullRequests.edges.map({
						$0.node.reviewRequests.edges.map({ $0.node.requestedReviewer })
					}).flatMap({ $0 })

					let reviewersReviewed = graphAPIResponse.data.repository.pullRequests.edges.map({
						$0.node.reviews.edges.map({ $0.node.author })
					}).flatMap({ $0 })

					let allEngineers = reviewersRequested.map({ Engineer(requestedReviewer: $0) }) + reviewersReviewed.map({ Engineer(author: $0) })

					_self.queryOpenPullRequests(involving: allEngineers.uniqueElements)
				} catch {
					print("JSON parsing error: \(error)")
				}
			case .failure:
				print("Failed to get all pull requests data.")
			}
		}
	}

	private func queryOpenPullRequests(involving engineers: [Engineer]) {
		guard let query = queryManager.openPullRequestsQuery else {
			return Logger.log("Query is empty.")
		}

		networkManager.query(query) { [weak self] result in
			guard let _self = self else {
				return
			}
			switch result {
			case .success(let data):
				do {
					let graphAPIResponse = try JSONDecoder().decode(GraphAPIResponse.self, from: data)

					_self.viewer = graphAPIResponse.data.viewer
					_self.pullRequests = graphAPIResponse.data.repository.pullRequests.edges.map({ $0.node })

					_self.reviewersSorted = engineers.sorted(by: { a, b in
						a.PRsToReview(in: _self.pullRequests).count < b.PRsToReview(in: _self.pullRequests).count
					})

					if let viewer = _self.viewer {
						let engineer = Engineer(viewer: viewer)
						let pullRequestsCount = _self.pullRequestsToReviewCount(for: engineer, in: _self.pullRequests)
						let isAttentionNeeded = _self.hasAnyConflicts(for: viewer, in: _self.pullRequests)
						let ownPullRequestsCount = _self.numberOfPullRequests(for: viewer, in: _self.pullRequests)
						let pullRequestsReviewedCount = _self.numberOfPullRequestsReviewed(by: viewer, in: _self.pullRequests)

						DispatchQueue.main.async {
							// TODO: This can be merged into single call.
							_self.view.updateStatusItem(title: "\(pullRequestsCount)", isAttentionNeeded: isAttentionNeeded)
							_self.view.updateViewerView(
								with: engineer,
								ownPullRequestsCount: ownPullRequestsCount,
								pullRequestsToReviewCount: pullRequestsCount,
								pullRequestsReviewed: pullRequestsReviewedCount
							)
						}
					}

					DispatchQueue.main.async {
						_self.view.didFinishRunning(reviewers: _self.reviewersSorted, viewer: _self.viewer)
					}
				} catch {
					print("JSON parsing error: \(error)")
				}
			case .failure:
				DispatchQueue.main.async {
					_self.view.didFailToRun()
				}
			}
		}
	}

	func pullRequestsToReviewCount(for engineer: Engineer, in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> Int {
		return engineer.PRsToReview(in: pullRequests).count
	}

	func hasAnyConflicts(for viewer: GraphAPIResponse.Data.Viewer, in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> Bool {
		return pullRequests.first(where: { $0.mergeable == "CONFLICTING" && $0.author.login == viewer.login }) != nil
	}

	func numberOfPullRequests(for viewer: GraphAPIResponse.Data.Viewer, in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> Int {
		return pullRequests.filter({ $0.author.login == viewer.login }).count
	}

	func numberOfPullRequestsReviewed(by viewer: GraphAPIResponse.Data.Viewer, in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> Int {
		return pullRequests.filter({ $0.reviews.edges.contains(where: { $0.node.author.login == viewer.login }) }).count
	}

	private var viewDataForReviewer: [ReviewerCellView.ViewData] {
		return reviewersSorted.map({
			viewData(for: $0)
		})
	}

	func viewData(for engineer: Engineer) -> ReviewerCellView.ViewData {
		let prsToReview = engineer.PRsToReview(in: pullRequests).count
		let prsReviewed = engineer.PRsReviewed(in: pullRequests).count
		let totalPRs = prsToReview + prsReviewed

		// If total is 0 then set both integer and max to 1 so the bar is full green.
		let levelIndicatorViewData = ReviewerCellView.ViewData.LevelIndicator(
			integerValue: totalPRs == 0 ? 1 : prsReviewed,
			maxValue: totalPRs == 0 ? 1 : Double(totalPRs)
		)

		return ReviewerCellView.ViewData(
			login: engineer.login,
			levelIndicator: levelIndicatorViewData,
			numberOfReviewedPRs: prsReviewed,
			totalNumberOfPRs: totalPRs,
			avatarURL: engineer.avatarURL
		)
	}

	// FIXME: Should not use UIKit subclasses.
	func viewDataForUserLoginCell(at rowIndex: Int) -> ReviewerCellView.ViewData {
		return viewDataForReviewer[reviewerIndexFor(row: rowIndex)]
	}

	func viewDataForSeparator(at rowIndex: Int) -> SeparatorCellView.ViewData {
		if rowIndex == 0 {
			return SeparatorCellView.ViewData(title: "available for review")
		} else if rowIndex == numberOfAvailableReviewers + 1 {
			return SeparatorCellView.ViewData(title: "others")
		} else {
			fatalError()
		}
	}

	private func reviewerIndexFor(row: Int) -> Int {
		if row <= numberOfAvailableReviewers {
			return row - 1
		} else {
			return row - 2
		}
	}

	func isSeparator(at rowIndex: Int) -> Bool {
		return rowIndex == 0 || rowIndex == numberOfAvailableReviewers + 1
	}

	private var numberOfAvailableReviewers: Int {
		return viewDataForReviewer.filter({ $0.numberOfReviewedPRs == $0.totalNumberOfPRs }).count
	}

	func openMyPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+author%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openAwaitingReviewPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+review-requested%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openReviewedPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+reviewed-by%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openAllPullRequests() {
		openMyPullRequests()
		openAwaitingReviewPullRequests()
		openReviewedPullRequests()
	}

	private func openBrowser(with url: URL) {
		Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [url.absoluteString])
	}
}
