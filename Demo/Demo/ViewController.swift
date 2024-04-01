//
//  ViewController.swift
//  YLMultiplePanGesture
//
//  Created by Lin on 2024/3/21.
//

import UIKit
import SnapKit

///首页
class ViewController: UIViewController {
    //MARK: 私有属性
    
    
    //MARK: 可访问属性
    ///选中数组
    public var selectedArr : [Int] = []
    ///item大小
    private lazy var itemSize : CGSize = {
        let width = (UIScreen.main.bounds.width - 2) / 3.0
        let height = (UIScreen.main.bounds.height - 5) / 6.0
        return CGSize(width: width, height: height)
    }()
    
    //MARK: 控件相关
    ///多选滑动手势
    private lazy var multiplePan : YLMultiplePanGesture = {
        let pan = YLMultiplePanGesture(target: self, action: nil)
        //多选代理
        pan.multipleDelegate = self
        //传入collection
        pan.collection = collection
        return pan
    }()
    ///测试collection
    private lazy var collection : UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: sizeLayout)
        view.backgroundColor = .white
        view.register(testCell.self, forCellWithReuseIdentifier: "reuseId")
//        //模拟有间距时候,测试滑动
//        view.contentInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    ///布局
    private lazy var sizeLayout : UICollectionViewFlowLayout = {
        let size = UICollectionViewFlowLayout()
        size.itemSize = itemSize
        size.minimumInteritemSpacing = 1
        size.minimumInteritemSpacing = 1
        return size
    }()
    
    //MARK: 程序入口
    //MARK: 多选Demo测试
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(44)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-30)
        }
        //在collection的父类添加手势
        view.addGestureRecognizer(multiplePan)
    }
}

//MARK: 代理
extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    //返回有多少个cell
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 999
    }
    //初始化cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuseId", for: indexPath) as! testCell
        cell.localtionId = indexPath.row
        cell.showImv.image = UIImage(named: "test")
        cell.lab.text = "\(indexPath.row)"
        ///多选手势是否选中
        if let multipleSelect = multiplePan.getCellIsSelectFromMultiple(getSelectIndexPath: indexPath) {
            cell.isSelect = multipleSelect
        } else {
            //获取不到就说明是未开启多选或者入参错误
            reloadCellSelect(cell: cell, indexPath: indexPath)
        }
        return cell
    }
    //点击cell修改选中状态
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! testCell
        cell.isSelect = !cell.isSelect
    }
    
    ///判断该cell是否需要选中
    public func reloadCellSelect(cell:testCell, indexPath:IndexPath){
        cell.isSelect = selectedArr.contains(where: { searchArr in
            return searchArr == indexPath.row
        })
    }
    
    ///通过坐标获取是否已选中
    public func getSelectStateFromIndexPath(indexPath:IndexPath) -> Bool {
        return selectedArr.contains(where: { searchSource in
            return searchSource == indexPath.row
        })
    }
}

//MARK: 多选
extension ViewController : YLMultiplePanGestureDelegate, UIGestureRecognizerDelegate {
    //开始滑动
    func multipleBeganCellSelected(fromIndex: IndexPath) -> Bool {
        (collection.cellForItem(at: fromIndex) as? testCell)?.isSelect ?? getSelectStateFromIndexPath(indexPath: fromIndex)
    }
    //返回cell选中的状态
    func shouldReturnCellSelectedState(indexPath: IndexPath) -> Bool {
        (collection.cellForItem(at: indexPath) as? testCell)?.isSelect ?? getSelectStateFromIndexPath(indexPath: indexPath)
    }
    //多选完成
    func multipleCompletion(_ changeIndex: [IndexPath], shouldAppend: Bool) {
        //如果需要添加
        if shouldAppend {
            //需要添加
            for index in changeIndex {
                selectedArr.append(index.row)
            }
        } else {
            //需要移除
            selectedArr.removeAll { searchInt in
                changeIndex.contains { searchIndexPath in
                    searchIndexPath.row == searchInt
                }
            }
        }
    }
    
    //将要改变
    func shouldOperationIndexPathWillChange(_ shouldOperationIndexPath: [IndexPath], shouldChangeIndexPath: IndexPath, shouldSelect: Bool) {
        if let cell = collection.cellForItem(at: shouldChangeIndexPath) as? testCell {
            cell.isSelect = shouldSelect
        }
    }
}

///测试cell
class testCell : UICollectionViewCell {
    ///唯一id仅测试
    public var localtionId:Int = 0
    ///是否选中
    public var isSelect:Bool = false {
        didSet {
            selectedImageView.isHidden = !isSelect
        }
    }
    ///图片
    public lazy var showImv:UIImageView = {
        let imv = UIImageView()
        
        return imv
    }()
    ///坐标
    public lazy var lab : UILabel = {
        let lab = UILabel()
        lab.font = .systemFont(ofSize: 28, weight: .medium)
        lab.textColor = .red
        return lab
    }()
    ///选中蒙层
    public lazy var selectedImageView : UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .topRight
        imv.image = UIImage(named: "selected")
        return imv
    }()
    ///初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(showImv)
        addSubview(selectedImageView)
        addSubview(lab)
        showImv.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        selectedImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        lab.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
