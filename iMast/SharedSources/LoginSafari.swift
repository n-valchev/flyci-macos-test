//
//  LoginSafari.swift
//  iMast
//
//  Created by rinsuki on 2018/07/23.
//  
//  ------------------------------------------------------------------------
//
//  Copyright 2017-2019 rinsuki and other contributors.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit
import SafariServices

protocol LoginSafari {
    func open(url: URL, viewController: UIViewController)
}

class LoginSafariNormal: LoginSafari {
    func open(url: URL, viewController: UIViewController) {
        let safariVC = SFSafariViewController(url: url)
        viewController.present(safariVC, animated: true, completion: nil)
    }
}

@available(iOS 11.0, *)
class LoginSafari11: LoginSafari {
    var authSession: SFAuthenticationSession?
    func open(url: URL, viewController: UIViewController) {
        self.authSession = SFAuthenticationSession(url: url, callbackURLScheme: nil, completionHandler: {callbackUrl, error in
            guard let callbackUrl = callbackUrl else {
                return
            }
            print(callbackUrl)
            viewController.view.window?.windowScene?.open(callbackUrl, options: nil, completionHandler: nil)
        })
        self.authSession?.start()
    }
}

func getLoginSafari() -> LoginSafari {
    if #available(iOS 11.0, *) {
        return LoginSafari11()
    } else {
        return LoginSafariNormal()
    }
}
