//
//  YL+UIcollectionView.swift
//  YLMultiplePanGesture
//
//  Created by Lin on 2024/3/21.
//

import UIKit

///滑动方向
@objc public enum ScrollViewMoveDirection : Int {
    ///向上
    case top = 0
    ///向左
    case left = 1
    ///向下
    case bottom = 2
    ///向右
    case right = 3
}

//MARK: 在collectionView中扩展向上/下/左/右移动
extension UICollectionView {
    /// 滑动,方向仅上下左右可用
    /// - Parameters:
    ///   - direction: 方向 仅支持上下左右
    ///   - distance: 距离
    ///   - completion: 完成回调,传出是否有动画
    /// - Returns: 是否执行了动画
    public func scrollViewMoveTo(direction:ScrollViewMoveDirection,
                                 distance:CGFloat = 30,
                                 completion:((_ animate:Bool) -> Void)? = nil) {
        ///最后所需移动到的点
        var movePoint = contentOffset
        //判断传入的方向
        switch direction {
        case .top : //如果是向上移动
            //向上移动对应的值
            movePoint.y = movePoint.y - distance
        case .left : //如果是向左移动
            //向左移动对应的值
            movePoint.x = movePoint.x - distance
        case .bottom : //如果是向下移动
            //向下移动对应的值
            movePoint.y = movePoint.y + distance
        case .right : //如果是向右移动
            //向右移动对应的值
            movePoint.x = movePoint.x + distance
        default : return
        }
        //判断该值是否可用,不可用的话修复为可用值
        if movePoint.y < 0 {
            movePoint.y = 0
        }
        if movePoint.x < 0 {
            movePoint.x = 0
        }
        ///Y轴最大值
        let maxY = contentSize.height - frame.height
        ///X轴最大值
        let maxX = contentSize.width - frame.width
        if movePoint.y > maxY {
            movePoint.y = maxY
        }
        if movePoint.x > maxX {
            movePoint.x = maxX
        }
        
        //如果有移动
        if movePoint != contentOffset {
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.setContentOffset(movePoint, animated: false)
            } completion: { success in
                completion?(true)
            }
        } else {
            //没有移动传出未执行动画
            completion?(false)
        }
    }
}

//MARK: 点与手势相关
extension UICollectionView {
    /// 是否需要向上/下/左/右移动
    /// - Parameter direction: 方向
    /// - Parameter currentPoint: 传入需要判断的触摸点
    /// - Returns: 返回是否需要移动
    public func needToMove(_ direction:ScrollViewMoveDirection,
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
