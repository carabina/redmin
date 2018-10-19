//
//  Endpoint.swift
//  redditlight
//
//  Created by Gabriel O'Flaherty-Chan on 2018-10-19.
//  Copyright © 2018 gabrieloc. All rights reserved.
//

import Foundation

let baseURL = URL(string: "https://www.reddit.com")!

public enum NetworkError: Error {
	case requestError, corruptResponse
}

public enum EndpointResponse<Response> {
	case success(Response)
	case failure(Error)
}

public protocol Resource: Codable {
}

public protocol Response: Decodable {
}

public protocol Endpoint {
	associatedtype R: Response
	var resourcePath: String { get }
	var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
	var queryItems: [URLQueryItem]? {
		return nil
	}
	
	var url: URL {
		let url = baseURL.appendingPathComponent("\(resourcePath).json")
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		components.queryItems = [URLQueryItem(name: "raw_json", value: "1")] + (queryItems ?? [])
		return components.url!
	}
	
	public func request(_ completion: @escaping ((EndpointResponse<R>) -> Void)) {
		let decoder = JSONDecoder()
		
		func createResponse(_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?) -> EndpointResponse<R> {
			guard let data = data else {
				return .failure(error ?? NetworkError.requestError)
			}
			
			do {
				let decoded = try decoder.decode(R.self, from: data)
				return .success(decoded)
			} catch (let error) {
				return .failure(error)
			}
		}
		
		let session = URLSession(configuration: .default)
		let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
			let response = createResponse(data, response, error)
			completion(response)
		})
		
		task.resume()
	}
}