//
//  HXLoadable.swift
//  HXEasyReader
//
//  Created by HongXiangWen on 2019/2/12.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

// MARK: -  HXXibLoadable
protocol HXXibLoadable {}
extension HXXibLoadable {
    
    /// 从xib中创建
    static func viewFromXib() -> Self {
        return Bundle.main.loadNibNamed("\(self)", owner: nil, options: nil)?.first as! Self
    }
    
}

extension UIView: HXXibLoadable {}

// MARK: -  HXXibLoadable
protocol HXStoryboardLoadable {}
extension HXStoryboardLoadable {

    /// 通过storyboardName创建
    ///
    /// - Parameter storyboardName: storyboardName
    /// - Returns: 创建好的实例
    static func viewControllerFromStoryboard(_ storyboardName: String) -> Self {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: "\(self)") as! Self
    }
    
}

extension UIViewController: HXStoryboardLoadable {}
