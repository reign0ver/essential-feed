//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 26/12/24.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  struct UnexpectedValuesRepresentation: Error {}
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url, completionHandler: { _, _, error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.failure(UnexpectedValuesRepresentation()))
      }
    }).resume()
  }
}

final class URLSessionHTTPClientTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }
  
  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }
  
  func test_getFromURL_performsGETRequestWithURL() {
    let url = makeAnyURL()
    let expectation = XCTestExpectation(description: "wait for request")
    
    URLProtocolStub.observeRequests { urlRequest in
      XCTAssertEqual(urlRequest.url, url)
      XCTAssertEqual(urlRequest.httpMethod, "GET")
      expectation.fulfill()
    }
    
    makeSUT().get(from: url, completion: { _ in })
    wait(for: [expectation], timeout: 1)
  }
  
  func test_getFromURL_failsOnRequestError() {
    let requestError = NSError(domain: "any error", code: 1)
    
    guard let receivedError = resultErrorFor(
      data: nil,
      response: nil,
      error: requestError
    ) as? NSError else {
      XCTFail("Expected an NSError")
      return
    }
    
    XCTAssertEqual(receivedError.domain, requestError.domain)
    XCTAssertEqual(receivedError.code, requestError.code)
  }
  
  func test_getFromURL_failsOnAllInvalidRepresentationCases() {
    let anyData = Data()
    let anyError = NSError(domain: "some error", code: 400)
    let nonHTTPURLResponse = URLResponse()
    let anyHTTPURLResponse = HTTPURLResponse()
    
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
  }
}

// MARK: Helpers
private extension URLSessionHTTPClientTests {
  func makeSUT(
    file: StaticString = #file,
    line: UInt = #line
  ) -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  func resultErrorFor(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Error? {
    URLProtocolStub.stub(data: data, response: response, error: error)
    
    let sut = makeSUT(file: file, line: line)
    let expectation = XCTestExpectation(description: "wait for completion")
    var receivedError: Error?
    
    sut.get(from: makeAnyURL()) { result in
      switch result {
      case let .failure(error):
        receivedError = error
      default:
        XCTFail("Expected failure, got \(result) instead", file: file, line: line)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1)
    return receivedError
  }
  
  func makeAnyURL() -> URL {
    URL(string: "http://any-url.com")!
  }
}

private extension URLSessionHTTPClientTests {
  final class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stub = Stub(data: data, response: response, error: error)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }
    
    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
      requestObserver = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
      requestObserver?(request)
      return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }
    
    override func startLoading() {
      if let data = URLProtocolStub.stub?.data {
        client?.urlProtocol(self, didLoad: data)
      }
      
      if let response = URLProtocolStub.stub?.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      
      if let error = URLProtocolStub.stub?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      
      client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
  }
}
