//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 8/12/24.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(
        url: URL,
        client: HTTPClient
    ) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.get(from: url)
    }
}
