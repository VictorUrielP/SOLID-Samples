import UIKit

/**
 Solución:
 
 - Se han creado las dos nuevas clases `URLSessionFetcher` y `JSONDecoderResultAdapter`.
 - Se han creado los protocolos `URLRequestFactory` y `DecodableResultAdapter`. (en la carpeta Sources)
 
 Beneficios:
 
 - Hemos logrado reutilizar código gracias a el uso de genéricos, pero lo más importante es que hemos aplicado OCP en la clase `URLSessionFetcher` ya que ahora nos permite extender su funcionalidad (open to extension) sin modificar su contenido (closed for modification).
 - Esto no quiere decir que esta clase no deba modificarse nunca más, por ejemplo en caso de tener algún bug o mejora del código claro que deberíamos modificarla.
 - Recuerda que el propósito de OCP es que sea fácil agregar nuevas funciones a nuestros módulos. Esto es algo que hemos logrado y que puedes ver más abajo a partir de la línea #57.
 
*/

final class URLSessionFetcher {
    
    private let urlRequestFactory: URLRequestFactory
    private let decodableResultAdapter: DecodableResultAdapter
    private struct DataNotFoundError: Error { }
    
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

final class JSONDecoderResultAdapter: DecodableResultAdapter {
    private let decoder: JSONDecoder
    
    private struct ModelDecodingError: Error { }
    
    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }
    
    func mapModel<T: Decodable>(data: Data) -> Result<T, Error> {
        guard let response = try? JSONDecoder().decode(T.self, from: data) else {
            return .failure(ModelDecodingError())
        }
        return .success(response)
    }
}

// MARK: - Uso del URLSessionFetcher fetcher para 🐱

let catsURLRequestFactory = CatsURLRequestFactory(hostName: "https://www.valid-cats-url.com")
let catsDecodableResultsAdapter = JSONDecoderResultAdapter(decoder: JSONDecoder())
let catsURLSessionFetcher = URLSessionFetcher(urlRequestFactory: catsURLRequestFactory,
                                              decodableResultAdapter: catsDecodableResultsAdapter)
catsURLSessionFetcher.fetchData() { (catsResult: Result<[Cat], Error>) in }

// MARK: - Uso del URLSessionFetcher fetcher para 🐶

let dogsURLRequestFactory = DogsURLRequestFactory(hostName: "https://www.valid-dogs-url.com")
let dogsDecodableResultsAdapter = JSONDecoderResultAdapter(decoder: JSONDecoder())
let dogsURLSessionFetcher = URLSessionFetcher(urlRequestFactory: dogsURLRequestFactory,
                                              decodableResultAdapter: catsDecodableResultsAdapter)
dogsURLSessionFetcher.fetchData() { (catsResult: Result<[Dog], Error>) in }

// MARK: - Aplicando más OCP para 🐦

/// Ahora incluso podrías extender la funcionalidad del `URLSessionFetcher` sin modificar su contenido.
/// Por ejemplo obteniendo datos de un nuevo servicio para obtener una lista de `Bird` en solo minutos.

struct Bird: Decodable {
    let id: String
    let breed: String
    let size: String
    let canFly: Bool
}

public final class BirdsURLRequestFactory: URLRequestFactory {
    
    private let hostName: String
    
    public init(hostName: String) {
        self.hostName = hostName
    }
    
    public func makeUrlRequest() -> URLRequest {
        let url = URL(string: "\(hostName)/birds")!
        let request = URLRequest(url: url)
        return request
    }
}

// MARK: - Uso del URLSessionFetcher fetcher para 🐦

let birdsURLRequestFactory = BirdsURLRequestFactory(hostName: "https://www.valid-birds-url.com")
let birdsDecodableResultsAdapter = JSONDecoderResultAdapter(decoder: JSONDecoder())
let birdsURLSessionFetcher = URLSessionFetcher(urlRequestFactory: birdsURLRequestFactory,
                                               decodableResultAdapter: birdsDecodableResultsAdapter)
birdsURLSessionFetcher.fetchData() { (catsResult: Result<[Dog], Error>) in }

// MARK: - Bonus challenge 💪🏼

/// El código de `CatsURLRequestFactory`, `DogsURLRequestFactory` y de `BirdsURLRequestFactory` tiene ciertas partes repetidas.
/// Ahora que ya conoces los principios de `SRP` y `OCP`:
/// 1. Identifica qué es lo que cambia entre ellas y las dos responsabilidades que tienen en común.
/// 2. Encapsula y delega lo que cambia (aplicando`SRP`).
/// 3. Crea un protocolo (aplicando `OCP`) para que un nuevo `URLRequestFactory` pueda extender su funcionalidad sin modificar su contenido.
/// 4. Inyecta tu nuevo factory en `URLSessionFetcher`y elimina el código duplicado.
