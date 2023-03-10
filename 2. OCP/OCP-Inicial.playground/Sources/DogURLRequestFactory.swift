import Foundation

public final class DogsURLRequestFactory {
    
    private let hostName: String
    
    init(hostName: String) {
        self.hostName = hostName
    }
    
    public func makeUrlRequest() -> URLRequest {
        let url = URL(string: "\(hostName)/dogs")!
        let request = URLRequest(url: url)

        return request
    }
}
