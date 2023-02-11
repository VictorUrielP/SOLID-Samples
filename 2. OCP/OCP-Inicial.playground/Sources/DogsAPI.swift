import Foundation

public final class DogsAPI {
    
    private let dogsURLRequestFactory: DogsURLRequestFactory
    private let dogsAdapter: DogsAdapter
    private struct DataNotFoundError: Error { }
    
    init(dogsURLRequestFactory: DogsURLRequestFactory, dogsAdapter: DogsAdapter) {
        self.dogsURLRequestFactory = dogsURLRequestFactory
        self.dogsAdapter = dogsAdapter
    }
    
    public func getDogs(completion: @escaping (Result<[Dog], Error>) -> Void) {
        let request = dogsURLRequestFactory.makeUrlRequest()
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, let data = data else { completion(.failure(DataNotFoundError())); return }
            completion(self.dogsAdapter.mapToResult(with: data))
        }
        
        dataTask.resume()
    }
}
