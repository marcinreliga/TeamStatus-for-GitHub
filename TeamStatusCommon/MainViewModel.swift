//
//  MainViewModel.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

protocol MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest], viewer: Viewer?)
	func didFailToRun()
	func updateStatusItem(title: String, isAttentionNeeded: Bool)
	func updateViewerView(with reviewer: Reviewer, ownPullRequestsCount: Int, pullRequestsToReviewCount: Int, pullRequestsReviewed: Int)
}

final class MainViewModel {
	private let view: MainViewProtocol
	private let queryManager: QueryManager = QueryManager()
	private let networkManager: NetworkManager

	private var reviewersSorted: [Reviewer] = []
	private var pullRequests: [PullRequest] = []
	private var viewer: Viewer?
	private var repositoryURL: URL

	//private var reviewers: [Reviewer] = []

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
				guard let apiResponse = _self.queryManager.parseResponse(data: data) else {
					return
				}

				let reviewersRequested = apiResponse.pullRequests.flatMap({ $0.reviewersRequested })
				let reviewersReviewed = apiResponse.pullRequests.flatMap({ $0.reviewersReviewed })
				let reviewers = (reviewersRequested + reviewersReviewed).uniqueElements
				
				_self.queryOpenPullRequests(involving: reviewers)
			case .failure:
				print("Failed to get all pull requests data.")
			}
		}
	}

	private func queryOpenPullRequests(involving reviewers: [Reviewer]) {
		guard let query = queryManager.openPullRequestsQuery else {
			return Logger.log("Query is empty.")
		}

		networkManager.query(query) { [weak self] result in
			guard let _self = self else {
				return
			}
			switch result {
			case .success(let data):
				if let apiResponse = _self.queryManager.parseResponse(data: data) {
					_self.reviewersSorted = reviewers.sorted(by: { a, b in
						a.PRsToReview(in: apiResponse.pullRequests).count < b.PRsToReview(in: apiResponse.pullRequests).count
					})

					let openPullRequests = apiResponse.pullRequests
					_self.pullRequests = openPullRequests
					_self.viewer = apiResponse.viewer

					if let viewer = _self.viewer {
						if let reviewer = _self.currentUserAsReviewer(viewer: viewer, in: _self.reviewersSorted) {
							let pullRequestsCount = _self.pullRequestsToReviewCount(for: reviewer, in: openPullRequests)
							let isAttentionNeeded = _self.hasAnyConflicts(for: viewer, in: openPullRequests)
							let ownPullRequestsCount = _self.numberOfPullRequests(for: viewer, in: openPullRequests)
							let pullRequestsReviewedCount = _self.numberOfPullRequestsReviewed(by: viewer, in: openPullRequests)

							DispatchQueue.main.async {
								// TODO: This can be merged into single call.
								_self.view.updateStatusItem(title: "\(pullRequestsCount)", isAttentionNeeded: isAttentionNeeded)
								_self.view.updateViewerView(
									with: reviewer,
									ownPullRequestsCount: ownPullRequestsCount,
									pullRequestsToReviewCount: pullRequestsCount,
									pullRequestsReviewed: pullRequestsReviewedCount
								)
							}
						}
					}

					DispatchQueue.main.async {
						_self.view.didFinishRunning(reviewers: _self.reviewersSorted, pullRequests: openPullRequests, viewer: apiResponse.viewer)
					}
				}
			case .failure:
				DispatchQueue.main.async {
					_self.view.didFailToRun()
				}
			}
		}
	}

	func currentUserAsReviewer(viewer: Viewer, in reviewers: [Reviewer]) -> Reviewer? {
		return reviewers.first(where: { $0.login == viewer.login})
	}

	func pullRequestsToReviewCount(for reviewer: Reviewer, in pullRequests: [PullRequest]) -> Int {
		return reviewer.PRsToReview(in: pullRequests).count
	}

	func hasAnyConflicts(for viewer: Viewer, in pullRequests: [PullRequest]) -> Bool {
		return pullRequests.first(where: { $0.mergeable == "CONFLICTING" && $0.authorLogin == viewer.login }) != nil
	}

	func numberOfPullRequests(for viewer: Viewer, in pullRequests: [PullRequest]) -> Int {
		return pullRequests.filter({ $0.authorLogin == viewer.login }).count
	}

	func numberOfPullRequestsReviewed(by viewer: Viewer, in pullRequests: [PullRequest]) -> Int {
		return pullRequests.filter({ $0.reviewersReviewed.contains(where: { $0.login == viewer.login }) }).count
	}

	// FIXME: Should not use UIKit subclasses.
	func viewDataForUserLoginCell(at rowIndex: Int) -> ReviewerCellView.ViewData {
		let reviewer = reviewersSorted[rowIndex]

		let prsToReview = reviewer.PRsToReview(in: pullRequests).count
		let prsReviewed = reviewer.PRsReviewed(in: pullRequests).count
		let totalPRs = prsToReview + prsReviewed

		// If total is 0 then set both integer and max to 1 so the bar is full green.
		let levelIndicatorViewData = ReviewerCellView.ViewData.LevelIndicator(
			integerValue: totalPRs == 0 ? 1 : prsReviewed,
			maxValue: totalPRs == 0 ? 1 : Double(totalPRs),
			warningValue: 0.5 * Double(totalPRs),
			criticalValue: 0.25 * Double(totalPRs)
		)

		return .init(
			login: reviewer.login,
			levelIndicator: levelIndicatorViewData,
			numberOfReviewedPRs: prsReviewed,
			totalNumberOfPRs: totalPRs
		)
	}

//	func viewDataForReviewedCell(at rowIndex: Int) -> ReviewedCellView.ViewData {
//		let reviewer = reviewersSorted[rowIndex]
//
//		let prsToReview = reviewer.PRsToReview(in: pullRequests).count
//		let prsReviewed = reviewer.PRsReviewed(in: pullRequests).count
//		let totalPRs = prsToReview + prsReviewed
//
//		return .init(pullRequestsReviewedText: "\(prsReviewed) of \(totalPRs)")
//	}

//	func viewDataForRequestedInCell(at rowIndex: Int) -> RequestedInCellView.ViewData {
////		let reviewer = reviewersSorted[rowIndex]
////
////		let prsToReview = reviewer.PRsToReview(in: pullRequests).count
////		let prsReviewed = reviewer.PRsReviewed(in: pullRequests).count
////		let totalPRs = prsToReview + prsReviewed
////
////		// If total is 0 then set both integer and max to 1 so the bar is full green.
////		return .init(
////			integerValue: totalPRs == 0 ? 1 : prsReviewed,
////			maxValue: totalPRs == 0 ? 1 : Double(totalPRs),
////			warningValue: 0.5 * Double(totalPRs),
////			criticalValue: 0.25 * Double(totalPRs)
////		)
//	}

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
