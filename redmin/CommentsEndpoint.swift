//
//  CommentsEndpoint.swift
//  Redmin
//
//  Created by Gabriel O'Flaherty-Chan on 2018-10-20.
//  Copyright © 2018 gabrieloc. All rights reserved.
//

import Foundation

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
	
	public let session = URLSession(configuration: .default)
	
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