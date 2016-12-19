//
//  LightsViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/18/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import UIKit

class LightCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(light: Light) {
        titleLabel.text = light.name
        backgroundColor = ColorUtility.color(
            from: light.state.colorspaceCoordinate,
            brightness: light.state.brightness,
            model: light.modelId
        )
    }
    
    class var identifier: String {
        return String(describing: self)
    }
    
    class var nib: UINib {
        return UINib(nibName: identifier, bundle: .main)
    }
}

class LightsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let user: WhitelistUser
    var lights: [Light] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(LightCollectionViewCell.nib, forCellWithReuseIdentifier: LightCollectionViewCell.identifier)
        }
    }
    
    init(user: WhitelistUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not supported initializer. user init(user:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BridgeManager
            .findBridges()
            .continueOnSuccessWith(continuation: { $0.first! } )
            .continueOnSuccessWith(continuation: { HueAPI.init(configuration: $0, user: self.user) })
            .continueOnSuccessWithTask(continuation: { $0.getLights() })
            .continueOnSuccessWith { (lights) -> Void in
                self.lights = lights
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LightCollectionViewCell.identifier, for: indexPath) as! LightCollectionViewCell
        let light = lights[indexPath.item]
        cell.configure(light: light)
        
        return cell
    }
    
}
