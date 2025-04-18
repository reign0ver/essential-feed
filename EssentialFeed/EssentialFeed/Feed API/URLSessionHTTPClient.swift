//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 24/03/25.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
  private let session: URLSession
  
  public init(session: URLSession = .shared) {
    self.session = session
  }
  
  private struct UnexpectedValuesRepresentation: Error {}
  
  public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url, completionHandler: { data, response, error in
      if let error {
        completion(.failure(error))
      } else if let data, let response = response as? HTTPURLResponse {
        completion(.success(data, response))
      } else {
        completion(.failure(UnexpectedValuesRepresentation()))
      }
    }).resume()
  }
}
