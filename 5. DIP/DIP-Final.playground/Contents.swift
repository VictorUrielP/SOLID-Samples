import UIKit

/**
 Solución:
 
 La clase `CatsViewController` dependía de detalles de implementación del backend.
 
 Recordemos que a pesar de estar utilizando protocolos, podemos seguir filtrando detalles de implementación como modelos de datos específicos del backend o que conforman con `Encodable` o `Decodable`.
 
 Esta es una práctica muy común, el inyectar estos modelos llenos de datos de backend que la UI no necesita. Esto hace que la capa de vista sea muy difícil de reutilizar y obliga a los desarrolladores a editar sus UIViewControllers cuando los detalles del backend o la persistencia cambian. (OOP)
 
 Para solucionar esto se demostró la implementación del closure `didSelect()` como una alternativa limpia para manejar este caso. Lo importante es entender que gracias a esta abstracción evitamos que `CatViewData` tuviera que conformar con `Encodable` o que necesitara datos adicionales (no necesarios por la vista) como en este caso el `identifier`.
 
 Ahora sí, nuestra vista depende completamente de abstracciones específicas para sus necesidades.
*/

// MARK: - New backend models.

struct Cat: Codable {
    let identifier: String
    let breed: String
    let size: Size
}

struct Size: Codable {
    let heightInCentimeters: Int
    let weightInKilograms: Int
    let description: String
}

// MARK: - Abstractions for the presentation layer.

/// Esta clase representa una abstracción con los datos específicos que necesita la vista, así como un closure de selección que sirve para no depender de los detalles de implementación del backend (`Cat`, `Codable`, `Decodable`) ni tener que inyectar datos innecesarios a nuestra vista (`identifier`).
struct CatViewData {
    let breed: String
    let size: String
    let didSelect: () -> Void
    
    init(breed: String, size: String, selection: @escaping () -> Void) {
        self.breed = breed
        self.size = size
        self.didSelect = selection
    }
}

/// Este protocolo es la abstracción de la que depende nuestra vista.
/// A través de ella le proveemos datos presentables (`CatViewData`).
protocol CatsService {
    func getCats(completion: @escaping (Result<[CatViewData], Error>) -> Void)
}

final class CatsServiceImp: CatsService {
    
    private let fetcher: Fetcher
    private let saver: Saver
    
    init(fetcher: Fetcher, saver: Saver) {
        self.fetcher = fetcher
        self.saver = saver
    }
    
    func getCats(completion: @escaping (Result<[CatViewData], Error>) -> Void) {
        fetcher.fetchData() { [weak self] (result: Result<[Cat], Error>) in
            switch result {
            case let .success(cats):
                completion(.success(self?.mapToViewData(cats) ?? []))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func mapToViewData(_ cats: [Cat]) -> [CatViewData] {
        cats.map { cat in
            CatViewData(breed: cat.breed, size: cat.size.description, selection: { [weak self] in
                self?.saveFavorite(cat)
            })
        }
    }
    
    private func saveFavorite(_ cat: Cat) {
        saver.saveData(data: cat, key: "favorite-cats-\(cat.identifier)") { result in
            switch result {
            case let .success(cat):
                print("Saved cat with identifier:", cat.identifier)
            case let .failure(error):
                print("Oops! An \(error) occured while saving:", cat)
            }
        }
    }
}

// MARK: - Presentation layer with Abstract Dependencies

final class CatsViewController {
    
    private let catsService: CatsService
    private var cats: [CatViewData] = []
    
    init(catsService: CatsService) {
        self.catsService = catsService
        
        callFetcher()
    }
    
    private func callFetcher() {
        catsService.getCats() { [weak self] (result: Result<[CatViewData], Error>) in
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
    
    private func iShouldBeCalledToLoadCats(_ cats: [CatViewData]) {
        self.cats = cats
        for cat in cats {
            print("Label - Cat Breed:", cat.breed)
            print("Label - Cat Size:", cat.size)
        }
    }
    
    func addFavoriteCat(at index: Int) {
        guard cats.count > index else { return }
        cats[index].didSelect()
    }
}

// MARK: - CatsRouter

final class CatsRouter {

    private let catsViewController: CatsViewController
    
    init() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodableResultsAdapter = JSONDecoderResultAdapter(decoder: decoder)
        let catsFetcher = LocalFileFetcher(fileName: "cats-v2", fileExtension: "json", decodableResultAdapter: decodableResultsAdapter)
        let favoriteCatsSaver = UserDefaultsSaver()
        let catsService = CatsServiceImp(fetcher: catsFetcher, saver: favoriteCatsSaver)
        catsViewController = CatsViewController(catsService: catsService)
    }
    
    func simulateUserSelectingCats() {
        print("MARK: - Start simulated cat selection")
        for index in 0...10 {
            catsViewController.addFavoriteCat(at: index)
        }
    }
}

let catsRouter = CatsRouter()
catsRouter.simulateUserSelectingCats()
