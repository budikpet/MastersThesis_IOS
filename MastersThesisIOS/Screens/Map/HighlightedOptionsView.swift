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
    func navigateClicked(highlightedOptionsView view: HighlightedOptionsView)
    func showAnimalsClicked(highlightedOptionsView view: HighlightedOptionsView)
}

/**
 A menu view that shows when features are highlighted in the map.
 */
class HighlightedOptionsView: UIView {
    private let viewModel: MapViewModeling
    public weak var delegate: HighlightedOptionsViewDelegate?

    private weak var stackView: UIStackView!
    private weak var navButton: UIButton!
    private weak var showAnimalsButton: UIButton!
    private weak var nameLabel: UILabel!

    // MARK: Initializers

    init(frame: CGRect, viewModel: MapViewModeling) {
        self.viewModel = viewModel
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
        showAnimalsButton.addTarget(self, action: #selector(showAnimalsButtonTapped(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [nameLabel, navButton, showAnimalsButton])
        self.stackView = stackView
        self.addSubview(stackView)
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(16)
            make.bottom.right.equalToSuperview().inset(8)
        }

        setupBindings()

        animateIn()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }

    private func setupBindings() {
        self.navButton.reactive.isEnabled <~ viewModel.highlightedLocations.map { $0.count == 1 }

        self.nameLabel.reactive.text <~ viewModel.highlightedLocations.producer.compactMap { (features: [TGMapFeature]) -> String? in
            if(features.count == 1) {
                return features.first?.properties["name"]?.capitalizingFirstLetter()
            } else if(features.count > 1) {
                return "Selected \(features.count) features"
            } else {
                return nil
            }
        }
    }
}

// MARK: Helpers

extension HighlightedOptionsView {
    /**
     Animate the view opening from bottom to top.
     */
    private func animateIn() {
        self.transform = CGAffineTransform(translationX: 0, y: self.frame.height)
        self.alpha = 1
        let animations: () -> Void = {
            self.transform = .identity
            self.alpha = 1
        }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn, animations: animations)
    }

    /**
     Animate the view closing from top to bottom.
     */
    func closeView() {
        let animations: () -> Void = { self.transform = CGAffineTransform(translationX: 0, y: self.frame.height) }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn, animations: animations) { (complete: Bool) in
            self.removeFromSuperview()
        }
    }

    @objc
    private func navButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.navigateClicked(highlightedOptionsView: self)
    }

    @objc
    private func showAnimalsButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.showAnimalsClicked(highlightedOptionsView: self)
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
