//
//  AnimalDetailVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 28/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift

protocol AnimalDetailFlowDelegate: class {

}

final class AnimalDetailVC: BaseViewController {

    // MARK: Dependencies

    private let viewModel: AnimalDetailViewModeling
    public weak var flowDelegate: AnimalDetailFlowDelegate?

    private weak var scrollView: UIScrollView!

    /** Main stack view. */
    private weak var stackView: UIStackView!
    private weak var characterView: UIStackView!

    // MARK: Initializers

    init(viewModel: AnimalDetailViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "AnimalDetailVC"

        let scrollView = UIScrollView()
        self.scrollView = scrollView
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }

        prepareStackView()
        prepareAnimalImageView()
        prepareCharacteristicsView()
        prepareText()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()
    }

    // MARK: Helpers

    private func setupBindings() {

        navigationItem.reactive.title <~ viewModel.animal.map() { $0.name }

//        activityIndicator.reactive.isAnimating <~ viewModel.actions.fetchPhoto.isExecuting
//
//        viewModel.actions.fetchPhoto <~ reloadButton.reactive.controlEvents(.touchUpInside).map { _ in }
//
//        imageView.reactive.image <~ viewModel.photo

    }

}

// MARK: Helpers

extension AnimalDetailVC {
    /**
     Prepares the main stack view.
     */
    private func prepareStackView() {
        let stackView = UIStackView()
        self.stackView = stackView
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(scrollView).offset(8)
            make.bottom.equalTo(scrollView).inset(8)
            make.left.equalTo(self.view).offset(8)
            make.right.equalTo(self.view).inset(8)
            make.width.equalTo(scrollView)
        }
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        stackView.axis = .vertical
    }

    private func prepareAnimalImageView() {
        guard let imageUrlString = viewModel.animal.value.image_url else { return }

        let imageAnimal = UIImageView()
        stackView.addArrangedSubview(imageAnimal)
        imageAnimal.sd_setImage(with: URL(string: imageUrlString),
                                placeholderImage: LexiconItemCellVM.placeholder_image,
                                options: .continueInBackground) { image, error, _, _ in
            if error != nil || image == nil {
                imageAnimal.isHidden = true
                return
            }

            guard let image = image else { return }
            let ratio = image.size.width / image.size.height
            imageAnimal.snp.makeConstraints { (make) in
                make.height.equalTo(imageAnimal.snp.width).multipliedBy(1/ratio)
            }
        }
        imageAnimal.contentMode = .scaleAspectFit
    }

    /**
     Prepares a view that contains all table information - name, latin name, class, food...
     */
    private func prepareCharacteristicsView() {
        let characterView = UIStackView()
        self.characterView = characterView
        self.stackView.addArrangedSubview(characterView)
        characterView.distribution = .equalSpacing
        characterView.spacing = 10
        characterView.axis = .vertical

        let property = viewModel.animal
        let values: [(String, Property<String>)] = [
            (L10n.AnimalDetail.labelName, property.map() { self.getCombinedString($0.name, $0.name_latin) }),
            (L10n.AnimalDetail.labelClass, property.map() { self.getCombinedString($0.class_, $0.class_latin) }),
            (L10n.AnimalDetail.labelOrder, property.map() { self.getCombinedString($0.order, $0.order_latin) }),
            (L10n.AnimalDetail.labelContinent, property.map() { self.getCombinedString($0.continent, $0.continent_detail) }),
            (L10n.AnimalDetail.labelBiotop, property.map() { self.getCombinedString($0.biotop, $0.biotop_detail) }),
            (L10n.AnimalDetail.labelFood, property.map() { self.getCombinedString($0.food, $0.food_detail) }),
            (L10n.AnimalDetail.labelSizes, property.map() { $0.sizes.capitalizingFirstLetter() }),
            (L10n.AnimalDetail.labelReproduction, property.map() { $0.reproduction.capitalizingFirstLetter() }),
            (L10n.AnimalDetail.labelLocation, property.map() { $0.createShownLocation() })
        ]

        for (name, value) in values {
            let labelName = UILabel()
            labelName.text = name
            labelName.font = UIFont.boldSystemFont(ofSize: 16.0)

            let labelValue = UILabel()
            labelValue.lineBreakMode = .byWordWrapping
            labelValue.numberOfLines = 0
            labelValue.reactive.text <~ value

            let valueStack = UIStackView(arrangedSubviews: [labelName, labelValue])
            valueStack.distribution = .fillEqually
            characterView.addArrangedSubview(valueStack)
        }
    }

    private func prepareText() {
        let label = UILabel()
        stackView.addArrangedSubview(label)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.reactive.text <~ viewModel.animal.map() { animal -> String in
            let texts = [animal.base_summary, animal.about_placement_in_zoo_prague, animal.interesting_data]
            return texts.filter() { $0 != "-" }.joined(separator: "\n\n")
            }
    }

    private func getCombinedString(_ a: String, _ b: String) -> String {
        let a = a.capitalizingFirstLetter()
        return b == "-" ? a : "\(a) (\(b))"
    }
}
