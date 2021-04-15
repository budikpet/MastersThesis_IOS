//
//  HighlightedOptionsView.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 15/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit

class HighlightedOptionsView: UIView {

    private weak var stackView: UIStackView!

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.systemBackground
        self.translatesAutoresizingMaskIntoConstraints = false

        let navButton = UIButton(type: .custom)
        navButton.setTitle("Navigate", for: [])
        navButton.setTitleColor(UIColor.gray, for: [])
        navButton.setImage(UIImage(named: "zooPragueLexiconIcon"), for: [])
        navButton.titleLabel?.font = navButton.titleLabel?.font.withSize(10)

        let showAnimalsButton = UIButton(type: .custom)
        showAnimalsButton.setTitle("Show animals", for: [])
        showAnimalsButton.setTitleColor(UIColor.gray, for: [])
        showAnimalsButton.setImage(UIImage(named: "zooMapIcon"), for: [])
        showAnimalsButton.titleLabel?.font = navButton.titleLabel?.font.withSize(10)

        let stackView = UIStackView(arrangedSubviews: [navButton, showAnimalsButton])
        self.stackView = stackView
        self.addSubview(stackView)
        stackView.distribution = .fillEqually
//        stackView.spacing = 20
        stackView.axis = .horizontal
        stackView.snp.makeConstraints { (make) in
//            make.top.left.equalToSuperview().offset(8)
//            make.bottom.right.equalToSuperview().inset(8)
            make.edges.equalToSuperview()
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()

        navButton.alignTextBelow()
        showAnimalsButton.alignTextBelow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
