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
class LexiconItemCell: UITableViewCell {
    private weak var labelName: UILabel!
    private weak var labelLocation: UILabel!
    private weak var imageAnimal: UIImageView!

    public static let identifier: String = "LexiconItemCell"
    private static let placeholder_image =  UIImage(systemName: "photo")!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let imageAnimal = UIImageView()
        addSubview(imageAnimal)
        self.imageAnimal = imageAnimal

        let labelName = UILabel()
        addSubview(labelName)
        self.labelName = labelName

        let labelLocation = UILabel()
        addSubview(labelLocation)
        self.labelLocation = labelLocation
        labelLocation.textColor = .lightGray

        // Constraints
        imageAnimal.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview().inset(8)
            make.width.equalTo(imageAnimal.snp.height).multipliedBy(1/1)
            make.height.equalTo(80)
        }

        labelName.snp.makeConstraints { make in
            make.top.equalTo(imageAnimal.snp.top).inset(8)
            make.leading.equalTo(imageAnimal.snp.trailing).offset(16)
        }

        labelLocation.snp.makeConstraints { make in
            make.top.equalTo(labelName.snp.bottom).offset(4)
            make.leading.equalTo(labelName.snp.leading)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Data-loading methods

    /**
    Load data of an Item into the cell.
    
    - Parameters:
       - data: `AnimalData` which should be displayed using the `AnimalData`.
    */
    func setData(using data: AnimalData) {
        labelName.text = data.name
        labelLocation.text = data.location_in_zoo
        imageAnimal.sd_setImage(with: URL(string: data.image_url),
                                placeholderImage: LexiconItemCell.placeholder_image,
                                options: .continueInBackground)
    }

}
