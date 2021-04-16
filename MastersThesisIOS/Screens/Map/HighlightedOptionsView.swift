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

class HighlightedOptionsView: UIView {
    private weak var stackView: UIStackView!

    private(set) weak var navigateClicked: Signal<(), Never>!
    private(set) weak var showAnimalsClicked: Signal<(), Never>!

    // MARK: Initializers

    init(frame: CGRect, feature: TGMapFeature) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.systemBackground
        self.translatesAutoresizingMaskIntoConstraints = false

        let props = feature.properties

        let nameLabel = UILabel()
        nameLabel.text = props["name"]?.capitalizingFirstLetter()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 25)

        let navButton = prepareButton(withText: "Directions")
        let showAnimalsButton = prepareButton(withText: "View animals")

        self.navigateClicked = navButton.reactive.controlEvents(.touchUpInside).map { _ in }
        self.showAnimalsClicked = showAnimalsButton.reactive.controlEvents(.touchUpInside).map { _ in }

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }

    private func setupBindings() {

    }
}

// MARK: Helpers

extension HighlightedOptionsView {
    private func prepareButton(withText text: String) -> UIButton {
        let res = UIButton(type: .custom)
        res.setTitle(text, for: [])
        res.setTitleColor(UIColor.white, for: [])
//        res.setBackgroundColor(color: UIColor(red: 3/255, green: 165/255, blue: 252/255, alpha: 1), forState: .highlighted)
//        res.setBackgroundColor(color: .systemBlue, forState: .highlighted)
        res.backgroundColor = .systemBlue
        res.layer.cornerRadius = 12

        return res
    }
}
