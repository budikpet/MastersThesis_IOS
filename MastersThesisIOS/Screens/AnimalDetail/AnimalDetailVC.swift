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

    private weak var rootView: UIScrollView!

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

//        let scrollView = UIScrollView(frame: view.bounds)
//        self.rootView = scrollView
//        view.addSubview(scrollView)
//        scrollView.isDirectionalLockEnabled = true

        let label = UILabel()
        view.addSubview(label)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(10)
            make.left.right.equalTo(self.view)
            make.width.height.equalToSuperview()
//            make.leading.trailing.equalToSuperview().offset(10)
        }
        label.text = """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis nec consectetur enim. Mauris ac turpis faucibus, ultricies velit in, fermentum tortor. Praesent sit amet sem consectetur, imperdiet nisi non, rhoncus dolor. Proin quis metus ex. Ut commodo diam ac egestas posuere. Nullam auctor dictum risus, sit amet consectetur ante congue sit amet. Curabitur rutrum vulputate arcu sed placerat. Quisque sed risus ac lacus condimentum dignissim.

            Nam suscipit lorem sed elementum lacinia. Maecenas a consequat dolor, eu venenatis lorem. Sed in vestibulum nisl, vel ultricies diam. Duis tincidunt nunc egestas elementum porttitor. Donec vel odio dolor. In eros dui, convallis fermentum tortor egestas, molestie viverra massa. Vivamus vel sem dolor. Vestibulum lacinia id ex ac ornare. Curabitur et pulvinar dui.

            Duis dignissim, purus vel tristique consectetur, augue magna scelerisque lectus, at lobortis ante purus quis nulla. Pellentesque sollicitudin gravida ante, id feugiat tortor euismod et. Duis suscipit felis vel ipsum efficitur condimentum. Nam sollicitudin lectus ut quam lobortis elementum. Etiam rhoncus varius odio, quis interdum quam. Sed eu eros sed magna volutpat eleifend. Phasellus congue feugiat justo, rutrum vehicula eros porta non. Etiam ut lacus vitae nisl fringilla porttitor. Aenean bibendum lectus sed blandit ullamcorper. Aenean gravida, nulla ac hendrerit pulvinar, felis mauris pretium nisi, nec sollicitudin massa tellus at nibh. Nam eu ornare risus. Sed vulputate odio sem, quis luctus dui iaculis non. Pellentesque condimentum volutpat augue, ac tincidunt odio viverra fringilla. Duis iaculis, tellus sit amet dictum cursus, augue mi fringilla nibh, a sodales elit velit vel arcu. Curabitur aliquet tristique dapibus.

            Nulla facilisi. Aliquam vitae sapien tempus, congue purus id, ultricies purus. Suspendisse euismod, odio vitae posuere fermentum, elit velit commodo mi, nec ultricies eros purus at odio. Ut vitae auctor sapien. Integer facilisis mi elit, et tristique mi gravida at. Sed luctus elit mauris, et aliquam mauris eleifend in. Proin mollis tincidunt purus, dapibus viverra elit volutpat ac. Pellentesque ut porttitor ante, a egestas sapien. Duis urna mi, fringilla et sapien sit amet, ultrices malesuada nisi. Vivamus quis maximus mi. Etiam ut nulla semper, porttitor purus bibendum, condimentum enim.

            Donec feugiat facilisis tempor. Suspendisse potenti. Proin nec pellentesque lorem, non blandit nunc. Sed in tortor eu enim ullamcorper iaculis. Sed faucibus posuere sem. Morbi luctus, sem vitae consequat rhoncus, felis metus condimentum felis, vel rutrum quam lorem sed urna. Vestibulum eget tempus elit. Curabitur vitae dolor eros. Vestibulum at placerat massa. Donec aliquam non tortor at ultricies. Sed gravida, dolor eu iaculis bibendum, felis nunc pellentesque mauris, ac gravida nibh sapien quis elit.
            """
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()
    }

    // MARK: Helpers

    private func setupBindings() {

//        activityIndicator.reactive.isAnimating <~ viewModel.actions.fetchPhoto.isExecuting
//
//        viewModel.actions.fetchPhoto <~ reloadButton.reactive.controlEvents(.touchUpInside).map { _ in }
//
//        imageView.reactive.image <~ viewModel.photo

    }

}