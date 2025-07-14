//
//  ComplexViewScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 26.01.24.
//

import BugsnagPerformance

@objcMembers
class ComplexViewScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
         super.setInitialBugsnagConfiguration()
         bugsnagPerfConfig.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
     }

     override func run() {
         let viewController = ComplexViewScenario_ViewController()
         _ = viewController.view
         UIApplication.shared.windows[0].rootViewController!.present(
             viewController, animated: true)
     }
 }

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 128, height: 128)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension UIView {
    func anchor (top: NSLayoutYAxisAnchor?,
                 left: NSLayoutXAxisAnchor?,
                 bottom: NSLayoutYAxisAnchor?,
                 right: NSLayoutXAxisAnchor?,
                 paddingTop: CGFloat,
                 paddingLeft: CGFloat,
                 paddingBottom: CGFloat,
                 paddingRight: CGFloat,
                 width: CGFloat,
                 height: CGFloat) {

        translatesAutoresizingMaskIntoConstraints = false

        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop+self.safeAreaInsets.top).isActive = true
        }
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom-self.safeAreaInsets.bottom).isActive = true
        }
        if height > 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if width > 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
}

struct ColorItem {

    var name : String
    var image : UIImage
    var description : String
}

class ColorItemCell : UITableViewCell {

    var item : ColorItem? {
        didSet {
            image.image = item?.image
            nameLabel.text = item?.name
            descriptionLabel.text = item?.description
        }
    }

    private let image : UIImageView = {
        let view = UIImageView(image: UIColor.white.image())
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private let nameLabel : UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        return label
    }()

    private let descriptionLabel : UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let decreaseButton : UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("-", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()

    private let increaseButton : UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("+", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()

    var itemQuantity : UILabel =  {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        label.text = "1"
        label.textColor = .black
        return label
    }()

    @objc func onDecrease() {
        adjustQuantity(by: -1)
    }

    @objc func onIncrease() {
        adjustQuantity(by: 1)
    }

    func adjustQuantity(by amount: Int) {
        var quantity = Int(itemQuantity.text!)! + amount
        if quantity < 0 {
            quantity = 0
        }
        itemQuantity.text = "\(quantity)"
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(image)
        image.anchor(top: topAnchor,
                     left: leftAnchor,
                     bottom: bottomAnchor,
                     right: nil,
                     paddingTop: 5,
                     paddingLeft: 5,
                     paddingBottom: 5,
                     paddingRight: 0,
                     width: 90,
                     height: 0)

        contentView.addSubview(nameLabel)
        nameLabel.anchor(top: topAnchor,
                         left: image.rightAnchor,
                         bottom: nil,
                         right: nil,
                         paddingTop: 20,
                         paddingLeft: 10,
                         paddingBottom: 0,
                         paddingRight: 0,
                         width: frame.size.width / 2,
                         height: 0)

        contentView.addSubview(descriptionLabel)
        descriptionLabel.anchor(top: nameLabel.bottomAnchor,
                                left: image.rightAnchor,
                                bottom: nil,
                                right: nil,
                                paddingTop: 0,
                                paddingLeft: 10,
                                paddingBottom: 0,
                                paddingRight: 0,
                                width: frame.size.width / 2,
                                height: 0)

        let stackView = UIStackView(arrangedSubviews: [decreaseButton,itemQuantity,increaseButton])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.spacing = 5
        contentView.addSubview(stackView)
        stackView.anchor(top: topAnchor,
                         left: nameLabel.rightAnchor,
                         bottom: bottomAnchor,
                         right: rightAnchor,
                         paddingTop: 15,
                         paddingLeft: 5,
                         paddingBottom: 15,
                         paddingRight: 10,
                         width: 0,
                         height: 70)
    
        increaseButton.addTarget(self, action: #selector(onIncrease), for: .touchUpInside)
        decreaseButton.addTarget(self, action: #selector(onDecrease), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
}

class ComplexViewScenario_ViewController: UIViewController {
    // Override so that these get instrumented
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let controller = ComplexViewScenario_TableViewController()
        controller.view.frame = self.view.bounds
        self.view.addSubview(controller.view)
        self.addChild(controller)
        controller.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

class ComplexViewScenario_TableViewController: UITableViewController {
    let cellId = "myCell"
    var colorItems : [ColorItem]  = [ColorItem]()

    // Override so that these get instrumented
    override func loadView() {
        super.loadView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        colorItems.append(ColorItem(name: "Orange", image: UIColor.orange.image(), description: "Nothing rhymes with it"))
        colorItems.append(ColorItem(name: "Red", image: UIColor.red.image(), description: "The strongest color"))
        colorItems.append(ColorItem(name: "Yellow", image:  UIColor.yellow.image(), description: "Sunflower color"))

        tableView.register(ColorItemCell.self, forCellReuseIdentifier: cellId)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ColorItemCell
        cell.item = colorItems[indexPath.row]
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorItems.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
