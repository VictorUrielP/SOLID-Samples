import Foundation

public final class URLSessionFetcher: Fetcher {
    
    private let urlRequestFactory: URLRequestFactory
    private let decodableResultAdapter: DecodableResultAdapter
    
    public init(urlRequestFactory: URLRequestFactory, decodableResultAdapter: DecodableResultAdapter) {
        self.urlRequestFactory = urlRequestFactory
        self.decodableResultAdapter = decodableResultAdapter
    }
    
    public func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
        let request = urlRequestFactory.makeUrlRequest()
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, let data = data else { completion(.failure(DataNotFoundError())); return }
            completion(self.decodableResultAdapter.mapModel(data: data))
        }
        
        dataTask.resume()
    }
}
