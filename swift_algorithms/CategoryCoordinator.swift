import UIKit

protocol CategoryCoordinatorDispatching {
    func dispatch(_ action: CategoryCoordinator.Action)
}

final class CategoryCoordinator {
    
    enum Action {
        case selectedAlgorithm(Algorithm)
        case selectedDataStructure(DataStructure)
    }
    
    private let algorithmCategoryFactory = AlgorithmSectionFactory()
    private let urlFactory = UrlFactory()
    private let stringNetworkService = StringNetworkService()
    
    var actionLookup: [UUID: Action] = [:]
    
    var nav: UINavigationController?
    
    func makeRoot(_ category: Algorithm.Category) -> UIViewController? {
        if category == .sorting {
            
            let sections = algorithmCategoryFactory.makeAllSortingSections()
            
            sections.forEach { section in
                section.identifiers.forEach { identifier in
                    switch identifier.value {
                    case let .selectedAlgorithm(algorithm):
                        actionLookup[identifier.key] = .selectedAlgorithm(algorithm)
                    default:
                        return
                    }
                }
            }
            
            let vc = makeAlgorithmCategoryViewController(category: category,
                                                         with: sections.map { $0.seciton })
            return vc
        } else {
            
            guard let section = algorithmCategoryFactory.makeSection(for: category) else {
                return nil
            }
            
            section.identifiers.forEach { identifier in
                switch identifier.value {
                case let .selectedAlgorithm(algorithm):
                    actionLookup[identifier.key] = .selectedAlgorithm(algorithm)
                default:
                    return
                }
            }
            
            let vc = makeAlgorithmCategoryViewController(category: category,
                                                         with: [section.seciton])
            return vc
        }
        
    }
    
    private func makeAlgorithmCategoryViewController(category: Algorithm.Category,
                                                     with sections: [TableSectionController]) -> UIViewController {
        let vc = CategoryDetailViewController()
        
        vc.onSelect = { [weak self] identifier in
            guard let action = self?.actionLookup[identifier] else {
                return
            }
            
            self?.dispatch(action)
        }
        
        vc.sections = sections
        vc.detail.cardView.render(CategoryTileItemView.Properties(category))
        
        let nav = UINavigationController(rootViewController: vc)
        nav.hero.isEnabled = true
        
        self.nav = nav
        
        return nav
    }
    
    private func makeMarkdownController(with markdown: String,
                                        title: String) -> MarkdownPresentationViewController {
        
        let controller = MarkdownPresentationViewController()
        controller.title = title
        controller.markdownView.load(markdown: markdown, enableImage: true)
        return controller
    }
    
    private func handleAlgorithmSelect(_ algorithm: Algorithm) {
        
        guard let url = urlFactory.markdownFileUrl(for: algorithm) else {
            return
        }
        
        handleMarkdownResourceSelect(with: url,
                                     resourceTitle: algorithm.navTitle,
                                     navigationStack: nav)
    }
    
    private func handleDataStructureSelect(_ dataStructure: DataStructure) {
        guard let url = urlFactory.markdownFileUrl(for: dataStructure) else {
            return
        }
        
        handleMarkdownResourceSelect(with: url,
                                     resourceTitle: dataStructure.title,
                                     navigationStack: nav)
    }
    
    private func handlePuzzleSelect(_ puzzle: Puzzle) {
        
        guard let url = urlFactory.markdownFileUrl(for: puzzle) else {
            return
        }
        
        handleMarkdownResourceSelect(with: url,
                                     resourceTitle: puzzle.title,
                                     navigationStack: nav)
    }
    
    private func handleMarkdownResourceSelect(with url: URL,
                                              resourceTitle: String,
                                              navigationStack: UINavigationController?) {
        
        stringNetworkService.fetchMarkdown(with: url) { [weak self] result in
            switch result {
            case let .success(markdown):
                
                DispatchQueue.main.async {
                    if let controller = self?.makeMarkdownController(with: markdown,
                                                                     title: resourceTitle) {
                        navigationStack?.pushViewController(controller, animated: true)
                    }
                }
                
            case .failure:
                return
            }
        }
    }
}

extension CategoryCoordinator: AlgorithmPresenterActionDispatching {
    func dispatch(_ action: AlgorithmPresentationAction) {
        switch action {
        case let .selectedAlgorithm(algorithm):
            handleAlgorithmSelect(algorithm)
        default:
            return
        }
    }
}

extension CategoryCoordinator: CategoryCoordinatorDispatching {
    func dispatch(_ action: CategoryCoordinator.Action) {
        switch action {
        case let .selectedAlgorithm(algorithm):
            handleAlgorithmSelect(algorithm)
        case let .selectedDataStructure(dataStructure):
            handleDataStructureSelect(dataStructure)
        }
    }
}
