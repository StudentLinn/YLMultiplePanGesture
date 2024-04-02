//
//  YLMultiplePanGesture.swift
//  YLMultiplePanGesture
//
//  Created by Lin on 2024/3/21.
//

import UIKit

///手势代理
@objc protocol YLMultiplePanGestureDelegate {
    /// 多选开始 => 请在这里面返回开始的cell对应的选中属性
    /// - Parameter fromIndex: 从什么坐标开始
    @objc func multipleBeganCellSelected(fromIndex : IndexPath) -> Bool
    
    /// 传入当前cell是否选中,请在这个代理返回这个cell是否已选中
    /// - Parameter index: 传出需要获取状态的cell坐标
    /// - Returns: 当前是否已选中
    @objc func shouldReturnCellSelectedState(indexPath : IndexPath) -> Bool
    
    /// 将要改变选中下标
    /// - Parameter shouldOperationIndexPath: 需要改变的数组
    /// - Parameter shouldChangeIndexPath: 将要改变的坐标
    /// - Parameter shouldSelect: 是否选中
    @objc optional func shouldOperationIndexPathWillChange(_ shouldOperationIndexPath : [IndexPath],
                                                           shouldChangeIndexPath : IndexPath,
                                                           shouldSelect : Bool)
    
    /// 已经改变选中下标
    /// - Parameter shouldOperationIndexPath: 需要改变的数组
    /// - Parameter shouldChangeIndexPath: 将要改变的坐标
    /// - Parameter shouldSelect: 是否选中
    @objc func shouldOperationIndexPathDidChange(_ shouldOperationIndexPath : [IndexPath],
                                                           shouldChangeIndexPath : IndexPath,
                                                           shouldSelect : Bool)
    
    /// 手势完成,根据代理传出的下标修改已选中数据
    /// - Parameters:
    ///   - changeIndex: 修改的坐标
    ///   - shouldAppend: 需要添加?移除
    @objc func multipleCompletion(_ changeIndex : [IndexPath],
                                  shouldAppend : Bool)
}

///多选手势状态
enum YLMultiplePanGestureState {
    ///默认 => 未启动
    case normal
    ///多选中
    case multipling
    ///滑动中，不执行多选
    case scrolling
}

//MARK: 属性相关
///多选手势
class YLMultiplePanGesture : UIPanGestureRecognizer {
    //MARK: 私有属性
    ///起始点位
    private var begintPoint : CGPoint?
    ///当前坐标
    private var currentIndexPath : IndexPath?
    ///当前滑动方向(暂不支持左右)
    private var moveDiretion : ScrollViewMoveDirection = .top
    
    //MARK: 可访问属性
    ///是否允许多选交互 => 默认开启
    public var isMultipleEnabled : Bool = true
    ///这个手势使用于哪个collectionVIew,未传入的话无法使用
    public var collection : UICollectionView?
    ///多选代理
    public var multipleDelegate : YLMultiplePanGestureDelegate?
    ///当前手指触摸坐标
    public var currentPoint : CGPoint?
    ///手势状态
    public var multipleState : YLMultiplePanGestureState = .normal 
    ///这个值指示开始的cell状态 => 需要在代理begin方法内修改
    public var beginCellIsChocie : Bool = false
    ///需要修改的数据
    public var shouldOperationIndexPath : [IndexPath] = []
    ///指示需要修改的数据是选中还是取消
    public var shouldOperationIndexNeedSelected : Bool {
        return !beginCellIsChocie
    }
    ///自动滑动标记=>默认开启
    public var autoScrollViewFlag : Bool = true
    ///是否正在自动滑动
    public var isAutoScrolling : Bool = false
    ///上下滑动多少后开启自动滑动
    public var moveYDistanceStartAutoScrolling : CGFloat = 50
    
    ///初始化参数 => 在每次结束手势时候自动调用
    public func initParameters(){
        //恢复默认
        multipleState = .normal
        //删除起始点
        begintPoint = nil
        //删除当前坐标记录
        currentIndexPath = nil
        //删除当前手指触摸点
        currentPoint = nil
        shouldOperationIndexPath = []
        //关闭自动滑动
        isAutoScrolling = false
    }
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        delegate = self
        addTarget(self, action: #selector(multipleAction))
    }
}

//MARK: 系统手势代理
extension YLMultiplePanGesture : UIGestureRecognizerDelegate {
    //是否允许多手势
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//MARK: 多选方法具体实现
extension YLMultiplePanGesture {
    ///多选手势action
    @objc private func multipleAction(_ pan:UIGestureRecognizer) {
        //TODO: 手势开始
        //手势开始
        if pan.state == .began {
            //未开启交互不执行
            if !isMultipleEnabled {
                return
            }
            //记录起始坐标
            begintPoint = pan.location(in: collection)
            
            //TODO: 手势改变
        } else if pan.state == .changed {
            //手势移动
            //未开启交互不执行
            if !isMultipleEnabled {
                return
            }
            //取消可选值
            guard let begintPoint, let collection else {
                return
            }
            //获取当前移动坐标
            let point = pan.location(in: collection)
            //起始坐标,如果没有在cell中开始的话不启动多选  //当前滑动到的坐标
            guard let beginIndexPath = collection.indexPathForItem(at: begintPoint), let movingIndexPath = collection.indexPathForItem(at: point) else {
                return
            }
            //记录当前手势
            currentPoint = point
            //如果未开启手势则开始判断
            if multipleState == .normal {
                ///间距
                let rowPadding = movingIndexPath.row - beginIndexPath.row
                ///组间距
                let sectionPadding = movingIndexPath.section - beginIndexPath.section
                //当前坐标与之前坐标没有改变
                if rowPadding == 0 && sectionPadding == 0 {
                    //就不往下执行了
                    return
                    //如果1 == row间距或者 == -1 并且 组间距为0
                } else if (rowPadding == 1 || rowPadding == -1) && sectionPadding == 0 {
                    //进入多选状态
                    multipleState = .multipling
                    //更新当前cell默认是否选中
                    beginCellIsChocie = multipleDelegate?.multipleBeganCellSelected(fromIndex: beginIndexPath) ?? false
                    //根据当前偏移量设定是否
                    if rowPadding == -1 {
                        //滑动方向为上
                        moveDiretion = .top
                    } else if rowPadding == 1 {
                        //滑动方向为下
                        moveDiretion = .bottom
                    }
                    //开启自动滑动 => 触发条件 isAutoScrolling 等待y轴滑动超过50后开启
                    collectionAutoMoving()
                } else {
                    //否则进入滑动状态
                    multipleState = .scrolling
                }
            }
            //如果当前未开启滑动
            if !isAutoScrolling {
                //执行判断逻辑
                ///移动距离
                let moveYDistance = point.y - begintPoint.y
                //如果y轴移动超过50
                if abs(moveYDistance) > moveYDistanceStartAutoScrolling {
                    isAutoScrolling = true
                }
            }
            
            //正在多选状态
            if multipleState == .multipling {
                //如果有当前坐标
                if let currentIndexPath {
                    //说明上次已经选中过
                    //判断当前方向
                    if moveDiretion == .top {
                        //当前是向上滑动
                        //如果当前滑动到的位置小于上一次滑动的位置那么是正确的
                        if movingIndexPath.row < currentIndexPath.row {
                            //选中这部分数据
                            choiceIndexPaths(beginIndexPath: currentIndexPath, endIndexPath: movingIndexPath)
                        } else if movingIndexPath.row > currentIndexPath.row {
                            //需要取消选中
                            //判断是否到了起始点
                            if movingIndexPath.row >= beginIndexPath.row {
                                //取消选中这部分的数据
                                cancelChoiceIndexPaths(beginIndexPath: currentIndexPath, endIndexPath: beginIndexPath)
                                //选中从起始点到现在的数据
                                choiceIndexPaths(beginIndexPath: beginIndexPath, endIndexPath: movingIndexPath)
                                //修改方向
                                moveDiretion = .bottom
                            } else {
                                //取消选中这部分的数据
                                cancelChoiceIndexPaths(beginIndexPath: currentIndexPath, endIndexPath: movingIndexPath)
                            }
                        }
                    } else if moveDiretion == .bottom {
                        //移动方向为下
                        //如果当前滑动的位置大于上一次滑动的位置那么是正确的
                        if movingIndexPath.row > currentIndexPath.row {
                            //选中这部分数据
                            choiceIndexPaths(beginIndexPath: currentIndexPath, endIndexPath: movingIndexPath)
                        } else if movingIndexPath.row < currentIndexPath.row {
                            //需要反选
                            //判断是否到了起始点
                            if movingIndexPath.row <= beginIndexPath.row {
                                //取消选中这部分的数据
                                cancelChoiceIndexPaths(beginIndexPath: currentIndexPath, endIndexPath: beginIndexPath)
                                //选中从起始点到现在的数据
                                choiceIndexPaths(beginIndexPath: beginIndexPath, endIndexPath: movingIndexPath)
                                //修改方向
                                moveDiretion = .top
                            } else {
                                //取消选中这部分的数据
                                cancelChoiceIndexPaths(beginIndexPath: movingIndexPath, endIndexPath: currentIndexPath)
                            }
                        }
                    }
                } else {
                    //选中起始到现在的这一部分数据
                    choiceIndexPaths(beginIndexPath: beginIndexPath, endIndexPath: movingIndexPath)
                }
            }
            //记录当前坐标为indexPath
            currentIndexPath = movingIndexPath
            
            //TODO: 手势结束
        } else if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            //结束手势
            //代理传出完成回调
            multipleDelegate?.multipleCompletion(shouldOperationIndexPath, shouldAppend: shouldOperationIndexNeedSelected)
            //初始化参数
            initParameters()
        }
    }
}

//MARK: 选中方法
extension YLMultiplePanGesture {
    ///选中这部分的下标
    public func choiceIndexPaths(beginIndexPath:IndexPath, endIndexPath:IndexPath){
        //判断是谁比较大
        if beginIndexPath.row < endIndexPath.row {
            //遍历这部分数据
            for row in beginIndexPath.row ... endIndexPath.row {
                //获取当前状态并选中从开始到现在的cell
                ///需要改变的坐标
                let changeIndexPath = IndexPath(row: row, section: endIndexPath.section)
                ///当前cell是否已选中
                let isSelect = multipleDelegate?.shouldReturnCellSelectedState(indexPath: changeIndexPath)
                //判断是否需要改变
                if shouldOperationIndexNeedSelected != isSelect {
                    //如果多选列表中没有该数据
                    if !shouldOperationIndexPath.contains(where: { searchIndexPath in
                        return searchIndexPath == changeIndexPath
                    }) { //那么才执行修改状态
                        //代理传出将要取消选中
                        multipleDelegate?.shouldOperationIndexPathWillChange?(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: shouldOperationIndexNeedSelected)
                        //需要改变状态的话就添加进入数组中
                        shouldOperationIndexPath.append(changeIndexPath)
                        //代理传出取消选中
                        multipleDelegate?.shouldOperationIndexPathDidChange(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: shouldOperationIndexNeedSelected)
                    }
                }
            }
        } else {
            //遍历这部分数据
            for row in endIndexPath.row ... beginIndexPath.row {
                //获取当前状态并选中从开始到现在的cell
                ///需要改变的坐标
                let changeIndexPath = IndexPath(row: row, section: endIndexPath.section)
                ///当前cell是否已选中
                let isSelect = multipleDelegate?.shouldReturnCellSelectedState(indexPath: changeIndexPath)
                //判断是否需要改变
                if shouldOperationIndexNeedSelected != isSelect {
                    //如果多选列表中没有该数据
                    if !shouldOperationIndexPath.contains(where: { searchIndexPath in
                        return searchIndexPath == changeIndexPath
                    }) { //那么才执行修改状态
                        //代理传出将要取消选中
                        multipleDelegate?.shouldOperationIndexPathWillChange?(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: shouldOperationIndexNeedSelected)
                        //需要改变状态的话就添加进入数组中
                        shouldOperationIndexPath.append(changeIndexPath)
                        //代理传出已经取消选中
                        multipleDelegate?.shouldOperationIndexPathDidChange(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: shouldOperationIndexNeedSelected)
                    }
                }
            }
        }
    }
    
    ///取消选中这部分的下标
    public func cancelChoiceIndexPaths(beginIndexPath:IndexPath, endIndexPath:IndexPath){
        //判断是谁比较大
        if beginIndexPath.row < endIndexPath.row {
            //遍历这部分数据
            for row in beginIndexPath.row ... endIndexPath.row {
                //获取当前状态并选中从开始到现在的cell
                ///需要改变的坐标
                let changeIndexPath = IndexPath(row: row, section: endIndexPath.section)
                ///当前cell是否已选中
                let isSelect = multipleDelegate?.shouldReturnCellSelectedState(indexPath: changeIndexPath)
                //判断是否需要改变
                if shouldOperationIndexNeedSelected == isSelect {
                    //如果多选列表中有该数据
                    if shouldOperationIndexPath.contains(where: { searchIndexPath in
                        return searchIndexPath == changeIndexPath
                    }) { //那么才执行,否则不改变状态
                        //代理传出将要取消选中
                        multipleDelegate?.shouldOperationIndexPathWillChange?(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: !shouldOperationIndexNeedSelected)
                        //需要改变状态的话就移除当前数据
                        shouldOperationIndexPath.removeAll { searchIndexPath in
                            return searchIndexPath == changeIndexPath
                        }
                        //代理传出已经取消选中
                        multipleDelegate?.shouldOperationIndexPathDidChange(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: !shouldOperationIndexNeedSelected)
                    }
                }
            }
        } else {
            //遍历这部分数据
            for row in endIndexPath.row ... beginIndexPath.row {
                //获取当前状态并选中从开始到现在的cell
                ///需要改变的坐标
                let changeIndexPath = IndexPath(row: row, section: endIndexPath.section)
                ///当前cell是否已选中
                let isSelect = multipleDelegate?.shouldReturnCellSelectedState(indexPath: changeIndexPath)
                //判断是否需要改变
                if shouldOperationIndexNeedSelected == isSelect {
                    //如果多选列表中有该数据
                    if shouldOperationIndexPath.contains(where: { searchIndexPath in
                        return searchIndexPath == changeIndexPath
                    }) { //那么才执行,否则不改变状态
                        //代理传出将要取消选中
                        multipleDelegate?.shouldOperationIndexPathWillChange?(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: !shouldOperationIndexNeedSelected)
                        //需要改变状态的话就移除当前数据
                        shouldOperationIndexPath.removeAll { searchIndexPath in
                            return searchIndexPath == changeIndexPath
                        }
                        //代理传出已经取消选中
                        multipleDelegate?.shouldOperationIndexPathDidChange(shouldOperationIndexPath, shouldChangeIndexPath: changeIndexPath, shouldSelect: !shouldOperationIndexNeedSelected)
                    }
                }
                
            }
        }
    }
}

//MARK: 滑动
extension YLMultiplePanGesture {
    ///根据当前滑动执行递归判断是否需要滑动
    private func collectionAutoMoving(){
        //如果当前不是多选手势 || 未开启多选就不往下执行了
        if multipleState != .multipling || isMultipleEnabled == false {
            return
        }
        ///当前滑动
        guard let currentPoint, let collection else {
            return
        }
        //如果不开启滑动
        if !autoScrollViewFlag {
            //不执行了
            return
        }
        //如果当前开启了自动滑动
        if isAutoScrolling {
            ///当前手势指向的坐标
            let location = currentPoint
            ///是否移动成功的flag
            var moveFlag : Bool = true
            
            //如果需要向上滑动
            if collection.needToMove(.top, currentPoint: location) {
                collection.scrollViewMoveTo(direction: .top, completion: collectionAutoMovingRecursionBlock)
            } else if collection.needToMove(.left, currentPoint: location) {
                //如果需要向左滑动
                collection.scrollViewMoveTo(direction: .left, completion: collectionAutoMovingRecursionBlock)
            } else if collection.needToMove(.bottom, currentPoint: location) {
                //如果需要向下滑动
                collection.scrollViewMoveTo(direction: .bottom, completion: collectionAutoMovingRecursionBlock)
            } else if collection.needToMove(.right, currentPoint: location) {
                //如果需要向右滑动
                collection.scrollViewMoveTo(direction: .right, completion: collectionAutoMovingRecursionBlock)
            } else {
                //标记为未移动
                moveFlag = false
            }
            //如果移动了
            if moveFlag {
                //重新走一遍手势的action
                multipleAction(self)
            } else {
                //执行没有走动画的回调 => 递归
                collectionAutoMovingRecursionBlock(false)
            }
        } else {
            //未开启
            //执行没有走动画的回调 => 递归
            collectionAutoMovingRecursionBlock(false)
        }
    }
    
    /// 继续执行递归的block回调
    /// - Parameter animate: 是否有执行动画
    private func collectionAutoMovingRecursionBlock(_ animate:Bool){
        //如果执行了动画
        if animate {
            //那么继续递归
            collectionAutoMoving()
        } else {
            //没有执行动画0.2秒后递归
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) { [weak self] in
                self?.collectionAutoMoving()
            }
        }
    }
}



//MARK: 指示这个cell是否已选中
extension YLMultiplePanGesture {
    /// 获取这个cell,或者坐标是否被多选手势选中，二选一即可获取
    /// - Returns: 是否被多选手势选中,为nil的两种可能 => 1.未开启多选 2.需要走外部判断
    public func getCellIsSelectFromMultiple(cell:UICollectionViewCell? = nil,
                                            getSelectIndexPath:IndexPath? = nil) -> Bool?{
        //未开启多选
        if multipleState != .multipling {
            return nil
        } else {
            //如果入参为cell
            if let cell {
                //获取不到坐标就return 掉
                guard let getSelectIndexPath = collection?.indexPath(for: cell) else {
                    print("error => getCellIsSelectFromMultiple.cell.indexPath get nilValue")
                    print("error => getCellIsSelectFromMultiple方法入参cell的indexPath获取不到")
                    return nil
                }
                //是否修改了该数据
                let multipleChangeCellSelect = shouldOperationIndexPath.contains { searchIndexPath in
                    return getSelectIndexPath == searchIndexPath
                }
                //如果修改了该数据
                if multipleChangeCellSelect {
                    //返回多选是选中?取消
                    return shouldOperationIndexNeedSelected
                } else {
                    //否则返回空进入外部判断
                    return nil
                }
            } else if let getSelectIndexPath {
                //如果入参为坐标
                //是否修改了该数据
                let multipleChangeCellSelect = shouldOperationIndexPath.contains { searchIndexPath in
                    return getSelectIndexPath == searchIndexPath
                }
                //如果修改了该数据
                if multipleChangeCellSelect {
                    //返回多选是选中?取消
                    return shouldOperationIndexNeedSelected
                } else {
                    //否则返回空进入外部判断
                    return nil
                }
            } else {
                //如果没有入参就返回空
                print("error => getCellIsSelectFromMultiple get nilValue")
                print("error => getCellIsSelectFromMultiple方法没有入参")
                return nil
            }
        }
    }
}
