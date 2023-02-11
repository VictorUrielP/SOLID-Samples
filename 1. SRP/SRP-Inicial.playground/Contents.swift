import Foundation

/**
 Instrucciones:
 
 - Identifica las múltiples responsabilidades en el método `getDogs()` de la clase `DogsAPI`.
 - Crea nuevas clases para cada una de las responsabilidades detectadas y reescribe la clase `DogsAPI` usando composición para mantener la funcionalidad actual.
 
 Tips:

 Para identificar las responsabilidades del método `getDogs()`, pregúntate:
 
 - ¿Cuáles son las funciones actuales de este módulo? ¿Tiene más de una función?
 - ¿Cuáles son las posibles razones por las que este módulo cambiaría?
*/

struct Dog: Decodable {
    let id: Int
    let breed: String
}

final class DogsAPI {
    
    private struct DogDecodingError: Error { }
    
    func getDogs(completion: @escaping (Result<[Dog], Error>) -> Void) {
        guard let url = URL(string: "http://dogsurlexample.com/dogs") else { return }
        let request = URLRequest(url: url)
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data,
                  let dogs = try? JSONDecoder().decode([Dog].self, from: data) else {
                completion(.failure(DogDecodingError()))
                return
            }
            
            completion(.success(dogs))
        }
        
        dataTask.resume()
    }
}
