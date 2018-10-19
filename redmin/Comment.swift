//
//  Comment.swift
//  redditlight
//
//  Created by Gabriel O'Flaherty-Chan on 2018-10-19.
//  Copyright © 2018 gabrieloc. All rights reserved.
//

import Foundation

public class Comment: Resource {
	public let author: String?
	public let body: String?
	public let score: Int?
	
	public var parent: Comment?
	public var replies: [Comment]?
	
	var replyNodes: Node<Comment>?
	
	public lazy var descendants: [Comment] = {
		var aggregation = [Comment]()
		aggregateDescendants(of: self, into: &aggregation)
		return aggregation
	}()
	
	public lazy var indentation: Int = {
		var indentation = 0
		var parent = self.parent
		while let p = parent {
			indentation += 1
			parent = p.parent
		}
		return indentation
	}()
	
	enum CodingKeys: String, CodingKey {
		case author, body, score, replyNodes = "replies"
	}
	
	required public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		author = try? container.decode(String.self, forKey: .author)
		body = try? container.decode(String.self, forKey: .body)
		score = try? container.decode(Int.self, forKey: .score)
		replyNodes = try? container.decode(Node<Comment>.self, forKey: .replyNodes)
		
		associateComments(for: replyNodes)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(body, forKey: .body)
		try container.encode(score, forKey: .score)
	}
	
	func aggregateDescendants(of comment: Comment, into collection: inout [Comment]) {
		comment.replies?.forEach { reply in
			collection.append(reply)
			aggregateDescendants(of: reply, into: &collection)
		}
	}
	
	func associateComments(for node: Node<Comment>?) {
		replies = node?.data.children?.map { $0.data }.filter { $0.body != nil }
		replies?.forEach { [unowned self] reply in
			reply.parent = self
			reply.associateComments(for: reply.replyNodes)
		}
	}
}

public struct CommentsResponse: Response {
	public let post: Post
	public let comments: [Comment]?
	
	public init(from decoder: Decoder) throws {
		var container = try decoder.unkeyedContainer()
		let postNode = try container.decode(Node<Post>.self)
		post = postNode.data.children![0].data
		
		let commentsNode = try? container.decode(Node<Comment>.self)
		comments = commentsNode?.data.children?.map { $0.data }
	}
}

public struct CommentsEndpoint: Endpoint {
	public typealias R = CommentsResponse
	
	public enum Sort: String {
		case confidence, top, new, controversial, old, random, qa, live
	}
	
	let path: String
	let sort: Sort
	let limit: Int
	
	public init(post: Post, sort: Sort, limit: Int) {
		self.path = post.commentsPath
		self.sort = sort
		self.limit = limit
	}
	
	public var resourcePath: String {
		return path
	}
	
	public var queryItems: [URLQueryItem]? {
		return [
			URLQueryItem(name: "sort", value: sort.rawValue),
			URLQueryItem(name: "limit", value: String(limit))
		]
	}
}