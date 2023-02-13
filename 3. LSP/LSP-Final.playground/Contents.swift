import UIKit

/**
 Solución:
 
 - 1. El error `DataNotFoundError` ahora está definido a nivel global de forma que ambos Fetcher puedan emitir el mismo tipo de error.
 - 2. A pesar de que parecía que `LocalFileFetcher`cumplía con ser subtipo de `URLSessionFetcher` ese pequeño detalle estaba rompiendo con LSP, ya que estos dos tipos no mantenían el mismo comportamiento de los clientes al ser sustituídos.
 - 3. Los principios de LSP y de OCP están fuertemente relacionados. De hecho utlizamos OCP al crear el `Fetcher` pero NO fue suficiente para garantizar que el código estuviera abierto para la extensión y cerrado para las modificaciones.
 - 4. El código también debe cumplir con el LSP para evitar efectos secundarios.

 Extra:
 
 - Revisa el playground LSP-SolucionErronea para ver un caso común de solucionar el problema inicial sin cumplir con LSP ni OCP.

*/

protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
}

struct DataNotFoundError: Error { }

extension DataNotFoundError: LocalizedError {
    public var errorDescription: String? {
        "Ha ocurrido un error al obtener los datos."
    }
}

final class LocalFileFetcher: Fetcher {
    
    private let fileName: String
    private let decodableResultAdapter: DecodableResultAdapter
    
    init(fileName: String, decodableResultAdapter: DecodableResultAdapter) {
        self.fileName = fileName
        self.decodableResultAdapter = decodableResultAdapter
    }
    
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
        let json = try? String(contentsOfFile: fileName)
        guard let data = json?.data(using: .utf8) else { completion(.failure(DataNotFoundError())); return }
        completion(decodableResultAdapter.mapModel(data: data))
    }
}

final class URLSessionFetcher: Fetcher {
    
    private let urlRequestFactory: URLRequestFactory
    private let decodableResultAdapter: DecodableResultAdapter
    
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
        print(error.localizedDescription)
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

