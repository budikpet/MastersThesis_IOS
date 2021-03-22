//
//  LexiconItemCell.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 22/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import SnapKit

/**
 Visual representation of Lexicon UITableViewCell.
 */
class LexiconItemCell: UITableViewCell {
    private weak var labelName: UILabel!
    private weak var labelLocation: UILabel!
    private weak var imageAnimal: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let imageAnimal = UIImageView()
        addSubview(imageAnimal)
        self.imageAnimal = imageAnimal
        imageAnimal.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageAnimal.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageAnimal.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageAnimal.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let labelName = UILabel()
        addSubview(labelName)
        self.labelName = labelName
        labelName.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelName.setContentHuggingPriority(.init(251), for: .vertical)
        labelName.setContentCompressionResistancePriority(.required, for: .horizontal)
        labelName.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        let labelLocation = UILabel()
        addSubview(labelLocation)
        self.labelLocation = labelLocation
        labelLocation.textColor = .lightGray
        labelLocation.setContentHuggingPriority(.init(251), for: .horizontal)
        labelLocation.setContentHuggingPriority(.init(251), for: .vertical)
        labelLocation.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        labelLocation.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        // Constraints
        imageAnimal.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.equalTo(imageAnimal.snp.height).multipliedBy(1/1)
            make.height.equalTo(30)
        }

        labelName.snp.makeConstraints { make in
            make.bottom.top.equalToSuperview().inset(8)
            make.leading.equalTo(imageAnimal.snp.trailing).offset(16)
            make.trailing.greaterThanOrEqualTo(labelLocation.snp.leading).offset(-8)
        }

        labelLocation.snp.makeConstraints { make in
            make.bottom.trailing.top.equalToSuperview().inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Data-loading methods

    /**
    Load data of an Item into the cell.
    
    - Parameters:
       - animal: `AnimalData` which should be displayed using the `ItemCell`.
    */
    func setData(using animal: AnimalData) {
        labelName.text = animal.name
        labelLocation.text = animal.location_in_zoo
        imageAnimal.image = UIImage(asset: Asset.testLama)
    }

}
