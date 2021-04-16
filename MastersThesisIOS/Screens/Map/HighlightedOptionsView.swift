//
//  HighlightedOptionsView.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 15/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import TangramMap
import ReactiveSwift

protocol HighlightedOptionsViewDelegate: class {
    func navigateClicked(highlightedOptionsView view: HighlightedOptionsView, feature: TGMapFeature)
    func showAnimalsClicked(highlightedOptionsView view: HighlightedOptionsView, features: [TGMapFeature])
}

class HighlightedOptionsView: UIView {
    private weak var stackView: UIStackView!
    private weak var navButton: UIButton!
    private weak var showAnimalsButton: UIButton!
    private weak var nameLabel: UILabel!

    public weak var delegate: HighlightedOptionsViewDelegate?

    private let features: MutableProperty<[TGMapFeature]>

    // MARK: Initializers

    init(frame: CGRect, features: [TGMapFeature]) {
        self.features = MutableProperty(features)
        super.init(frame: frame)

        self.backgroundColor = UIColor.systemBackground
        self.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        self.nameLabel = nameLabel
        nameLabel.font = UIFont.boldSystemFont(ofSize: 25)

        let navButton = prepareButton(withText: "Directions")
        self.navButton = navButton
        navButton.addTarget(self, action: #selector(navButtonTapped(_:)), for: .touchUpInside)

        let showAnimalsButton = prepareButton(withText: "View animals")
        self.showAnimalsButton = showAnimalsButton

        let stackView = UIStackView(arrangedSubviews: [nameLabel, navButton, showAnimalsButton])
        self.stackView = stackView
        self.addSubview(stackView)
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(8)
            make.bottom.right.equalToSuperview().inset(8)
        }

        setupBindings()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }

    func updateFeature(_ features: [TGMapFeature]) {
        self.features.value = features
    }

    func closeView() {
        self.removeFromSuperview()
    }

    private func setupBindings() {
        self.navButton.reactive.isEnabled <~ features.map { $0.count == 1 }

        self.nameLabel.reactive.text <~ features.producer.compactMap { (features: [TGMapFeature]) -> String? in
            if(features.count == 1) {
                return features.first?.properties["name"]?.capitalizingFirstLetter()
            } else {
                return "Selected \(features.count) features"
            }
        }
    }
}

// MARK: Helpers

extension HighlightedOptionsView {
    @objc
    private func navButtonTapped(_ sender: UIBarButtonItem) {
        guard let feature = features.value.first else { return }

        delegate?.navigateClicked(highlightedOptionsView: self, feature: feature)
    }

    @objc
    private func showAnimalsButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.showAnimalsClicked(highlightedOptionsView: self, features: features.value)
    }

    private func prepareButton(withText text: String) -> UIButton {
        let res = UIButton()
        res.setTitle(text, for: [])
        res.setTitleColor(UIColor.white, for: [])
//        res.setBackgroundColor(color: UIColor(red: 3/255, green: 165/255, blue: 252/255, alpha: 1), forState: .highlighted)
//        res.setBackgroundColor(color: .systemBlue, forState: .highlighted)
        res.setBackgroundColor(color: .systemBlue, forState: .normal)
        res.setBackgroundColor(color: .lightGray, forState: .disabled)
        res.layer.cornerRadius = 12

        return res
    }
}
