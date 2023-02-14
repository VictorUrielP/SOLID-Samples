import UIKit

/**
 Solución:
 
 - Utilizando el ISP creamos otro protocolo (interfaz) llamada `Saver` que contenga el método específico necesario para cumplir con su funcionalidad.
 - También creamos una implementación específica llamada `UserDefaultsSaver`que refleja mejor el comportamiento del código guardando datos en los User Defaults.
 
 Principios que se estaban rompiendo en la solución inicial:
 - 1. SRP: Ya que `LocalFileFetcher` tenía la responsabilidad adicional de guardar datos en los `UserDefaults`, algo que además era poco intuitivo ya que este fetcher  debería tener funcionalidad relacionada a archivos locales.
 - 2. LSP: Ya que la clase `URLSessionFetcher` tenía un método sin implementación, por que que esta clase no era sustituíble en los clientes de `Saver` y podría romper su funcionalidad.
 - 3. ISP: Finalmente detectamos que el problema era que la interfaz `Fetcher` tenía un método adicional no necesariamente relacionado a su funcionalidad original o a su dominio.

*/

public protocol Saver {
    func saveData<T: Encodable>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void)
}

protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
}

public final class UserDefaultsSaver: Saver {
    public func saveData<T>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void) where T : Encodable {
        guard let encodedData = try? JSONEncoder().encode(data) else { return completion(.failure(DataNotFoundError())) }
        UserDefaults.standard.set(encodedData, forKey: key)
        completion(.success(data))
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
