import UIKit

/**
 Solución Erronea:
 
 En esta solución logramos obtener el mismo comportamiento en la clase `CatsViewController`utilizando validaciones y casteo de datos en la función de la línea #81.
 
 Esta solución es erronea ya que no solo rompe LSP sino que también rompe OCP.
    - No cumple con LSP porque `LocalFileFetcher` NO es un subtipo reemplazable de `URLSessionFetcher` y se sigue rompiendo la regla de `Exceptions`, por ello debemos hacer un casteo de `Fetcher` a `LocalFileFetcher` para lograr mantener el mismo comportamiento que teníamos con `URLSessionFetcher`.
    - Si en el futuro necesitáramos agregar un nuevo tipo de `Fetcher` y reemplazarlo en `CatsViewController` tendríamos que agregar un nuevo `if statement` para mantener el comportamiento actual. Esto nos indica que `CatsViewController` NO está cerrado a su modificación, rompiendo así OCP.
*/

protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
}

final class LocalFileFetcher: Fetcher {
    
    private let fileName: String
    private let decodableResultAdapter: DecodableResultAdapter
    struct LocalDataNotFoundError: Error { }
    
    init(fileName: String, decodableResultAdapter: DecodableResultAdapter) {
        self.fileName = fileName
        self.decodableResultAdapter = decodableResultAdapter
    }
    
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
        let json = try? String(contentsOfFile: fileName)
        guard let data = json?.data(using: .utf8) else { completion(.failure(LocalDataNotFoundError())); return }
        completion(decodableResultAdapter.mapModel(data: data))
    }
}

final class URLSessionFetcher: Fetcher {
    
    private let urlRequestFactory: URLRequestFactory
    private let decodableResultAdapter: DecodableResultAdapter
    struct DataNotFoundError: Error { }
    
    init(urlRequestFactory: URLRequestFactory, decodableResultAdapter: DecodableResultAdapter) {
        self.urlRequestFactory = urlRequestFactory
        self.decodableResultAdapter = decodableResultAdapter
    }
    
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
        let request = urlRequestFactory.makeUrlRequest()
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, let data = data else { completion(.failure(DataNotFoundError())); return }
            completion(self.decodableResultAdapter.mapModel(data: data))
        }
        
        dataTask.resume()
    }
}

final class CatsViewController {
    
    private let fetcher: Fetcher
    private let caller: String
    
    init(fetcher: Fetcher, caller: String) {
        self.fetcher = fetcher
        self.caller = caller
        
        callFetcher()
    }
    
    private func callFetcher() {
        fetcher.fetchData() { [weak self] (result: Result<[Cat], Error>) in
            switch result {
            case let .success(cats):
                self?.iShouldBeCalledToLoadCats(cats)
            case let .failure(error):
                self?.iShouldBeCalledWhenAnErrorOccurs(error)
            }
        }
    }
    
    private func iShouldBeCalledWhenAnErrorOccurs(_ error: Error) {
        if error is URLSessionFetcher.DataNotFoundError {
            print("Ha ocurrido un error al obtener los datos.")
        }
        
        if fetcher is LocalFileFetcher, error is LocalFileFetcher.LocalDataNotFoundError {
            print("Ha ocurrido un error al obtener los datos.")
        }
    }
    
    private func iShouldBeCalledToLoadCats(_ cats: [Cat]) {
        print(cats)
    }
}

let catsURLRequestFactory = CatsURLRequestFactory(hostName: "https://www.valid-cats-url.com")
let catsDecodableResultsAdapter = JSONDecoderResultAdapter(decoder: JSONDecoder())

// Remote fetcher
let catsURLSessionFetcher = URLSessionFetcher(urlRequestFactory: catsURLRequestFactory,
                                              decodableResultAdapter: catsDecodableResultsAdapter)
// Local fetcher
let catsLocalFileFetcher = LocalFileFetcher(fileName: "filename.json",
                                             decodableResultAdapter: catsDecodableResultsAdapter)

let catsViewController = CatsViewController(fetcher: catsURLSessionFetcher, caller: "URLSessionFetcher")
let catsBROKENViewController = CatsViewController(fetcher: catsLocalFileFetcher, caller: "LocalFileFetcher")

