//
//  AnimalFilterItemCell.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 22/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import SnapKit
import ReactiveSwift

/**
 Visual representation of AnimalFilter UITableViewCell.
 */
class AnimalFilterItemCellVC: UITableViewCell {
    private weak var labelValue: UILabel!
    private weak var imageCheckmark: UIImageView!

    public static let identifier: String = "AnimalFilterItemCell"

    var viewModel: AnimalFilterItemCellVM! {
        didSet {
            labelValue.text = viewModel.value
            imageCheckmark.reactive.isHidden <~ viewModel.isChecked.map() { !$0 }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let labelValue = UILabel()
        addSubview(labelValue)
        self.labelValue = labelValue

        let imageCheckmark = UIImageView()
        addSubview(imageCheckmark)
        self.imageCheckmark = imageCheckmark
        imageCheckmark.contentMode = .scaleAspectFit
        imageCheckmark.image = UIImage(cgImage: AnimalFilterItemCellVM.checkmarkImg.cgImage!)
        imageCheckmark.accessibilityIdentifier = "FilterItemCell_CheckMark"

        // Constraints

        labelValue.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        imageCheckmark.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
