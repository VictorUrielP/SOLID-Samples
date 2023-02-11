import Foundation

public final class CatsURLRequestFactory: URLRequestFactory {
    
    private let hostName: String
    
    public init(hostName: String) {
        self.hostName = hostName
    }
    
    public func makeUrlRequest() -> URLRequest {
        let url = URL(string: "\(hostName)/cats")!
        let request = URLRequest(url: url)
        return request
    }
}
