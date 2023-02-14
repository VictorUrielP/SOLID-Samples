import UIKit

/**
 Contexto:
 
 Te han solicitado que agregues una nueva pantalla con una lista de gatitos 🐱.
 
 Para ello te basaste en el código de `DogsAPI` y creaste `CatsAPI` pero has notado 2 cosas:
 - 1. El codigo de `CatsAPI` cumple con la misma funcionalidad de `DogsAPI`.
 - 2. El código que usas para decodificar tus modelos también es muy parecido.
 
 Ambas clases están duplicadas y te preguntas:
 ¿No sería mejor modificar estas clases para permitirles extender su funcionalidad sin modificar su contenido?
 
 Instrucciones:
 
 - 1. Crea una clase `URLSessionFetcher` que contenga lo mismo que la clase `CatsAPI`.
 - 2. Renombra la función `getCats` a `fetchData` y utilza genéricos:
    - Reescribe la función: `fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)`
 - 4. Crea un protocolo `URLRequestFactory` con un método `makeUrlRequest() -> URLRequest`
    - Haz que `CatsURLRequestFactory` y `DogsURLRequestFactory`conformen con este protocolo.
 - 5. Crea un protocolo `DecodableResultAdapter`
    - Agrégale un método: `mapModel<T: Decodable>(data: Data) -> Result<T, Error>`.
    - Crea una clase `JSONDecoderResultAdapter`que conforme con `DecodableResultAdapter`.
 - 6. Utiliza inyección de dependencias en el constructor de `URLSessionFetcher`:
    - Cambia `CatsURLRequestFactory` por `URLRequestFactory`.
    - Cambia `DecodableResultAdapter` por `URLSessionFetcher`
 - 7. Elimina el código repetido: `DogsAPI`, `CatsAPI`, `DogsAdapter`y `CatsAdapter`.
*/

public struct Cat: Decodable {
    let id: Int
    let breed: String
    let size: String
}

final class CatsURLRequestFactory {
    
    private let hostName: String
    
    init(hostName: String) {
        self.hostName = hostName
    }
    
    func makeUrlRequest() -> URLRequest {
        let url = URL(string: "\(hostName)/cats")!
        let request = URLRequest(url: url)

        return request
    }
}

final class CatsAdapter {
    private let decoder: JSONDecoder
    
    private struct CatDecodingError: Error { }
    
    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }
    
    func mapToResult(with data: Data) -> Result<[Cat], Error> {
        guard let cats = try? JSONDecoder().decode([Cat].self, from: data) else {
            return .failure(CatDecodingError())
        }
        return .success(cats)
    }
}

final class CatsAPI {
    
    private let catsURLRequestFactory: CatsURLRequestFactory
    private let catsAdapter: CatsAdapter
    private struct DataNotFoundError: Error { }
    
    init(catsURLRequestFactory: CatsURLRequestFactory, catsAdapter: CatsAdapter) {
        self.catsURLRequestFactory = catsURLRequestFactory
        self.catsAdapter = catsAdapter
    }
    
    func getCats(completion: @escaping (Result<[Cat], Error>) -> Void) {
        let request = catsURLRequestFactory.makeUrlRequest()
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, let data = data else { completion(.failure(DataNotFoundError())); return }
            completion(self.catsAdapter.mapToResult(with: data))
        }
        
        dataTask.resume()
    }
}
