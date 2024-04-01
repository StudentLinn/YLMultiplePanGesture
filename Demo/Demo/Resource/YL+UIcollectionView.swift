//
//  YL+UIcollectionView.swift
//  YLMultiplePanGesture
//
//  Created by Lin on 2024/3/21.
//

import UIKit

///滑动方向
public enum ScrollViewMoveDirection {
    ///向上
    case top
    ///向左
    case left
    ///向下
    case bottom
    ///向右
    case right
}

//MARK: 在collectionView中扩展向上/下/左/右移动
extension UICollectionView {
    /// 滑动,方向仅上下左右可用
    /// - Parameter direction: 方向
    public func scrollViewMoveTo(direction:UICollectionView.ScrollPosition) {
        ///当前可见数组
        var visibleIndex = indexPathsForVisibleItems
        //排序
        visibleIndex.sort { leftIndex, rightIndex in
            return leftIndex.row < rightIndex.row
        }
        ///cell总数量
        let itemCount = numberOfItems(inSection: visibleIndex.first?.section ?? 0)
        //如果数量==0就不执行
        if itemCount == 0 {
            return
        }
        //如果数量
        //判断传入的方向
        switch direction {
        case .top : //如果是向上移动
            fallthrough //穿透，因为与向左一致
        case .left : //如果是向左移动
            //获取第一个数据
            guard let first = visibleIndex.first else {
                return
            }
            //判断当前是否还有向上移动的空间
            if first.row == 0 && first.section == 0 {
                return
            } else {
                //如果还能向上移动就向上移动1个坐标
                scrollToItem(at: IndexPath(row: first.row - 1, section: first.section), at: direction, animated: true)
            }
        case .bottom : //如果是向下移动
            fallthrough //穿透，因为与向右一致
        case .right : //如果是向右移动
            //获取最后一个数据
            guard let last = visibleIndex.last else {
                return
            }
            //判断当前是否还有向下移动的空间
            if last.row >= itemCount - 1 {
                return
            } else {
                //如果还能向下移动就移动1个坐标
                scrollToItem(at: IndexPath(row: last.row + 1, section: last.section), at: direction, animated: true)
            }
        default : return
        }
    }
}

//MARK: 点与手势相关
extension UICollectionView {
    /// 是否需要向上/下/左/右移动
    /// - Parameter direction: 方向
    /// - Parameter currentPoint: 传入需要判断的触摸点
    /// - Returns: 返回是否需要移动
    public func needToMove(_ direction:UICollectionView.ScrollPosition,
                           currentPoint:CGPoint) -> Bool {
        ///移动除的倍数
        let moveNeedScale:CGFloat = 5.0
        ///下半部分乘积 => 默认是移动被除数-1
        let bottomTake:CGFloat = moveNeedScale - 1.0
        //根据当前可见大小判断各部分是否需要移动
        switch direction {
        case .top : //向上
            ///是否向上移动
            let topNeedMove = visibleSize.height / moveNeedScale
            return currentPoint.y < contentOffset.y + topNeedMove
        case .left : //向左
            ///是否向左移动
            let leftNeedMove = visibleSize.width / moveNeedScale
            return currentPoint.x < contentOffset.x + leftNeedMove
        case .bottom : //向下
            ///是否向下移动
            let bottomNeedMove = visibleSize.height / moveNeedScale * bottomTake
            return currentPoint.y > contentOffset.y + bottomNeedMove
        case .right : //向右
            ///是否向右移动
            let rightNeedMove = visibleSize.width / moveNeedScale * bottomTake
            return currentPoint.x > contentOffset.x + rightNeedMove
        default : return false //其他
        }
    }
}
