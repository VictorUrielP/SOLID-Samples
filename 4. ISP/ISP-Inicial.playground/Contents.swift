import UIKit

/**
 Contexto:
 
 Alguien de tu equipo ha enviado un pull request y está solicitando tu aprobación.
 
 La descripción del PR dice lo siguiente: "Se ha agrregado funcionalidad para guardar animales en una lista de favoritos en User Defaults."
 
 Al revisar el código te das cuenta de que han agregado un nuevo método `saveData` al protocolo `Fetcher`. Ahora que ya conoces los principios SOLID parece que hay algo mal en este cambio.

 Instrucciones:
 
 - Identifica los principios de SOLID que se están rompiendo en este PR.
 - Utiliza el ISP ayudarle a tu compañero a resolver los problemas identificados.

*/

protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
    func saveData<T: Encodable>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void)
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
    
    func saveData<T: Encodable>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let encodedData = try? JSONEncoder().encode(data) else { return completion(.failure(DataNotFoundError())) }
        UserDefaults.standard.set(encodedData, forKey: key)
        completion(.success(data))
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
    
    func saveData<T: Encodable>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void) {
        // TODO: This functionality is currently not available in our backend service.
    }
    
}
