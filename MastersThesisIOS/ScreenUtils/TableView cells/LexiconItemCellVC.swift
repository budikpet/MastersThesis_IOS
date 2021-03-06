//
//  LexiconItemCell.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 22/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage

/**
 Visual representation of Lexicon UITableViewCell.
 */
class LexiconItemCellVC: UITableViewCell {
    private weak var labelName: UILabel!
    private weak var labelLocation: UILabel!
    private weak var imageAnimal: UIImageView!

    public static let identifier: String = "LexiconItemCell"

    var viewModel: LexiconItemCellVM! {
        didSet {
            labelName.text = viewModel.name
            labelLocation.text = viewModel.location
            imageAnimal.sd_setImage(with: viewModel.imageUrl,
                                    placeholderImage: LexiconItemCellVM.placeholder_image,
                                    options: .continueInBackground)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let imageAnimal = UIImageView()
        addSubview(imageAnimal)
        self.imageAnimal = imageAnimal
        imageAnimal.contentMode = .scaleAspectFit

        let labelName = UILabel()
        addSubview(labelName)
        self.labelName = labelName

        let labelLocation = UILabel()
        addSubview(labelLocation)
        self.labelLocation = labelLocation
        labelLocation.textColor = .lightGray
        labelLocation.lineBreakMode = .byWordWrapping
        labelLocation.numberOfLines = 2

        // Constraints
        imageAnimal.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview().inset(8)
            make.width.equalTo(imageAnimal.snp.height)
        }

        labelName.snp.makeConstraints { make in
            make.top.equalTo(imageAnimal.snp.top).inset(8)
            make.leading.equalTo(imageAnimal.snp.trailing).offset(16)
        }

        labelLocation.snp.makeConstraints { make in
            make.top.equalTo(labelName.snp.bottom).offset(4)
            make.leading.equalTo(labelName.snp.leading)
            make.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
