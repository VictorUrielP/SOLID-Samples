import UIKit

/**
 Solución:
 - Se identificaron 3 responsabilidades en total:
    - 1. Creación de un URLRequest.
    - 2. Obtener los datos.
    - 3. Decodificar los datos.
 - Las responsabilidades 1 y 3 se delegaron a nuevas clases.
*/

struct Dog: Decodable {
    let id: Int
    let breed: String
}

/// La clase `DogsURLRequestFactory` encapsula la creación de un `URLRequest`.
/// Si el request cambiara solo tendrías que modificar esta clase.
/// Por ejemplo porque el path cambió a `/dogs-list`.
final class DogsURLRequestFactory {
    
    private let hostName: String
    
    init(hostName: String) {
        self.hostName = hostName
    }
    
    func makeUrlRequest() -> URLRequest {
        let url = URL(string: "\(hostName)/dogs")!
        let request = URLRequest(url: url)

        return request
    }
}

/// La clase `DogsAdapter` encapsula las reglas de decodificación.
/// Si el estas reglas cambiaran solo tendrías que modificar esta clase.
/// Por ejemplo porque queremos devolver un error personalizado cuando el array está vacío.
final class DogsAdapter {
    private let decoder: JSONDecoder
    
    private struct DogDecodingError: Error { }
    
    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }
    
    func mapToResult(with data: Data) -> Result<[Dog], Error> {
        guard let dogs = try? JSONDecoder().decode([Dog].self, from: data) else {
            return .failure(DogDecodingError())
        }
        return .success(dogs)
    }
}

/// La clase `DogsAPI`ahora solo se modificaria si la manera de ejecutar el request o manejar la respuesta cambiara.
/// Por ejemplo si quisiéramos usar `Async await` en lugar de `completion blocks`.
/// O por ejemplo si quisiéramos validar el código de `response` previo a decodificar los datos.
final class DogsAPI {
    
    private let dogsURLRequestFactory: DogsURLRequestFactory
    private let dogsAdapter: DogsAdapter
    private struct DataNotFoundError: Error { }
    
    init(dogsURLRequestFactory: DogsURLRequestFactory, dogsAdapter: DogsAdapter) {
        self.dogsURLRequestFactory = dogsURLRequestFactory
        self.dogsAdapter = dogsAdapter
    }
    
    func getDogs(completion: @escaping (Result<[Dog], Error>) -> Void) {
        /// La creación de un request se delegó a la clase factory.
        let request = dogsURLRequestFactory.makeUrlRequest()
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, let data = data else { completion(.failure(DataNotFoundError())); return }
            /// La decodificación y manejo de errores se delegó a la clase adapter.
            completion(self.dogsAdapter.mapToResult(with: data))
        }
        
        dataTask.resume()
    }
}
