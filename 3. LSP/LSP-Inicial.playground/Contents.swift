import UIKit

/**
 Contexto:
 
 Volvamos a nuestro URLSessionFetcher. Tu manager te ha solicitado agregar una caché de datos para los usuarios que no tienen buen internet.

 Entonces, has creado un protocolo `Fetcher` que implementa el método `fetchData` de `URLSessionFetcher`. Esta es una buena idea ya que el código que funciona con `URLSessionFetcher` puede funcionar con `Fetcher` porque que la API permanece igual.

 Te han dicho que es una funcionalidad urgente, así que has creado rápidamente la función nueva clase `LocalFileFetcher: Fetcher` que obtiene datos de un archivo de caché y has escrito rápidamente la función `fetchData`.
 
 - Por la prisa, cometiste un error y rompiste la relga de `Exceptions`; y es que `URLSessionFetcher` emite un error cuando no se ha podido obtener data del request y en `LocalFileFetcher` no se emiten errores, simplemente se termina la función sin llamar el completion block.
 - Esto es malo ya que tu vista `CatsViewController` ahora no está mostrando el mensaje de error correcto a los usuarios.
 
 Instrucciones:
 
 - 1. Emite el error `LocalDataNotFoundError` cuando la data está vacía. ¿Se obtuvo el mismo comportamiento?
 - 2. Busca una forma de garantizar que ambos clientes emitan el mismo tipo de error, de forma que no rompan la funcionalidad de `CatsViewController`.
 
 Pistas:
 
 - Recuerda la regla de `Exeptions` dice que el método de subtipo tiene que arrojar las mismas excepciones del supertipo.
*/

protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
}

final class LocalFileFetcher: Fetcher {
    
    private let fileName: String
    private let decodableResultAdapter: DecodableResultAdapter
    private struct LocalDataNotFoundError: Error { }
    
    init(fileName: String, decodableResultAdapter: DecodableResultAdapter) {
        self.fileName = fileName
        self.decodableResultAdapter = decodableResultAdapter
    }
    
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
        let json = try? String(contentsOfFile: fileName)
        guard let data = json?.data(using: .utf8) else { return }
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
            print("Ocurrió un error al obtener los datos desde:", caller)
        } else {
            print("Ocurrió un error desconocido desde:", caller)
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
