import Foundation

public protocol URLRequestFactory {
    func makeUrlRequest() -> URLRequest
}
