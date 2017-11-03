//
//  Mock.swift
//  Rabbit
//
//  Created by Antoine van der Lee on 04/05/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//
//  Mocker is only used for tests. In tests we don't even check on this SwiftLint warning, but Mocker is available through Rabbit for usage out of Rabbit. Disable for this case.
//  swiftlint:disable force_unwrapping

import Foundation

/// A Mock which can be used for mocking data requests with the `Mocker` by calling `Mocker.register(...)`.
public struct Mock: Equatable {
    
    /// HTTP method definitions.
    ///
    /// See https://tools.ietf.org/html/rfc7231#section-4.3
    public enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }
    
    /// The types of content of a request. Will be used as Content-Type header inside a `Mock`.
    public enum DataType: String {
        case json
        case html
        case imagePNG
        case pdf
        case mp4
        case zip
        
        var headerValue: String {
            switch self {
            case .json:
                return "application/json; charset=utf-8"
            case .html:
                return "text/html; charset=utf-8"
            case .imagePNG:
                return "image/png"
            case .pdf:
                return "application/pdf"
            case .mp4:
                return "video/mp4"
            case .zip:
                return "application/zip"
            }
        }
    }
    
    /// The type of the data which is returned.
    public let dataType: DataType
    
    /// The headers to send back with the response.
    public let headers: [String: String]
    
    /// The HTTP status code to return with the response.
    public let statusCode: Int
    
    /// The URL value generated based on the Mock data.
    public let url: URL
    
    /// The file extensions to match for.
    public let fileExtensions: [String]?
    
    /// The data which will be returned as the response based on the HTTP Method.
    private let data: [HTTPMethod: Data]
    
    /// Add a delay to a certain mock, which makes the response returned later.
    public var delay: DispatchTimeInterval?
    
    private init(url: URL? = nil, dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:], fileExtensions: [String]? = nil) {
        self.dataType = dataType
        self.statusCode = statusCode
        self.data = data
        self.url = url ?? URL(string: "https://mocked.wetransfer.com/\(dataType.rawValue)/\(statusCode)/")!
        self.fileExtensions = fileExtensions?.map({ $0.replacingOccurrences(of: ".", with: "") })
        
        var headers = additionalHeaders
        headers["Content-Type"] = dataType.headerValue
        self.headers = headers
    }
    
    /// Creates a `Mock` for the given data type. The mock will be automatically matched based on a URL created from the given parameters.
    ///
    /// - Parameters:
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(url: nil, dataType: dataType, statusCode: statusCode, data: data, additionalHeaders: additionalHeaders, fileExtensions: nil)
    }
    
    /// Creates a `Mock` for the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to match for and to return the mocked data for.
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(url: URL, dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(url: url, dataType: dataType, statusCode: statusCode, data: data, additionalHeaders: additionalHeaders, fileExtensions: nil)
    }
    
    /// Creates a `Mock` for the given file extensions. The mock will only be used for urls matching the extension.
    ///
    /// - Parameters:
    ///   - fileExtensions: The file extension to match for.
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(fileExtensions: String..., dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(url: nil, dataType: dataType, statusCode: statusCode, data: data, additionalHeaders: additionalHeaders, fileExtensions: fileExtensions)
    }
    
    /// Registers the mock with the shared `Mocker`.
    public func register() {
        Mocker.register(self)
    }
    
    /// Returns `Data` based on the HTTP Method of the passed request.
    ///
    /// - Parameter request: The request to match data for.
    /// - Returns: The `Data` which matches the request. Will be `nil` if no data is registered for the request `HTTPMethod`.
    func data(for request: URLRequest) -> Data? {
        guard let requestHTTPMethod = Mock.HTTPMethod(rawValue: request.httpMethod ?? "") else { return nil }
        return data[requestHTTPMethod]
    }
    
    /// Used to compare the Mock data with the given `URLRequest`.
    static func == (mock: Mock, request: URLRequest) -> Bool {
        guard let requestHTTPMethod = Mock.HTTPMethod(rawValue: request.httpMethod ?? "") else { return false }
        
        if let fileExtensions = mock.fileExtensions {
            // If the mock contains a file extension, this should always be used to match for.
            guard let pathExtension = request.url?.pathExtension else { return false }
            return fileExtensions.contains(pathExtension)
        } else {
            return mock.url == request.url && mock.data.keys.contains(requestHTTPMethod)
        }
    }
    
    public static func == (lhs: Mock, rhs: Mock) -> Bool {
        let lhsHTTPMethods: [String] = lhs.data.keys.flatMap { $0.rawValue }
        let rhsHTTPMethods: [String] = lhs.data.keys.flatMap { $0.rawValue }
        return lhs.url.absoluteString == rhs.url.absoluteString && lhsHTTPMethods == rhsHTTPMethods
    }
}
