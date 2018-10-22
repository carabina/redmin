//
//  Comment.swift
//  redditlight
//
//  Created by Gabriel O'Flaherty-Chan on 2018-10-19.
//  Copyright © 2018 gabrieloc. All rights reserved.
//

import Foundation

public struct Comment: Resource {
	internal static let font: UIFont = .systemFont(ofSize: 14)
	
	public let author: String
	public let body: String
	public let score: Int
	
	public let id: String
	public let parentID: String
	public let depth: Int

	var replyNode: Node<ListingNode<Conversation.Item>>?

	public let bodyHTML: NSAttributedString
	
	enum CodingKeys: String, CodingKey {
		case author
		case body
		case depth
		case id
		case parentID = "parent_id"
		case bodyHTML = "body_html"
		case replyNode = "replies"
		case score
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		author = try container.decode(String.self, forKey: .author)
		body = try container.decode(String.self, forKey: .body)
		depth = try container.decode(Int.self, forKey: .depth)
		id = try container.decode(String.self, forKey: .id)
		parentID = try container.decode(String.self, forKey: .parentID)
		score = try container.decode(Int.self, forKey: .score)
		replyNode = try? container.decode(Node<ListingNode<Conversation.Item>>.self, forKey: .replyNode)
	
		let rawHTML = try container.decode(String.self, forKey: .bodyHTML)
		bodyHTML = rawHTML.htmlAttributedString(font: Comment.font)
	}

	static func aggregateDescendants(of comment: Comment, into collection: inout [Comment]) {
		let itemNodes = comment.replyNode?.data.children
		let comments: [Comment]? = itemNodes?.compactMap { itemNode in
			guard case Conversation.Item.comment(let comment) = itemNode.data else {
				return nil
			}
			return comment
		}
		comments?.forEach { reply in
			collection.append(reply)
			aggregateDescendants(of: reply, into: &collection)
		}
	}
	
}

extension String {
	public func htmlAttributedString(font: UIFont) -> NSAttributedString {
		let fontFamily = font.familyName == UIFont.systemFont(ofSize: 14).familyName ? "'-apple-system', 'HelveticaNeue', 'sans-serif'" : font.familyName
		let format = "<span style=\"font-family: \(fontFamily); font-size: \(font.pointSize)\">%@</span>"
		let formatted = String(format: format, trimmingCharacters(in: .whitespacesAndNewlines))
		
		guard
			let data = formatted.data(using: String.Encoding.utf16, allowLossyConversion: false),
			let attributedString = try? NSMutableAttributedString(
				data: data,
				options: [
					.documentType: NSAttributedString.DocumentType.html,
					.characterEncoding: String.Encoding.utf8.rawValue
				],
				documentAttributes: nil)
			else {
				return NSAttributedString(string: self)
		}
		if let lastCharacter = attributedString.string.last, lastCharacter == "\n" {
			attributedString.deleteCharacters(in: NSRange(location: attributedString.length-1, length: 1))
		}
		return attributedString
	}
}
