/*
* nodekit.io
*
* Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import WebKit

extension NKJSContextFactory {
    func createContextWKWebView(options: [String: AnyObject] = Dictionary<String, AnyObject>(), delegate cb: NKScriptContextDelegate) -> Int
    {
        let id = NKJSContextFactory.sequenceNumber
        
        let createContextMainThread = {()-> Void in
            log("+Starting NodeKit Nitro JavaScript Engine E\(id)")
            
            var item = Dictionary<String, AnyObject>()
            NKJSContextFactory._contexts[id] = item;
            
            let config = WKWebViewConfiguration()
            let webPrefs = WKPreferences()
            webPrefs.javaScriptEnabled = true
            webPrefs.javaScriptCanOpenWindowsAutomatically = true
            
            config.preferences = webPrefs
            
            let webView = WKWebView(frame: CGRectZero, configuration: config)
            
            webView.navigationDelegate = NKWKWebViewDelegate(id: id, webView: webView, delegate: cb);
            
            item["WKWebView"] = webView
            
            objc_setAssociatedObject(webView, unsafeAddressOf(NKJSContextId), id, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // must call callback before page load as all plugins need to be initialized at this stage to secure channel
            cb.NKScriptEngineLoaded(webView)
            
            webView.loadHTMLString("<HTML><BODY>NodeKit WKWebView: VM \(id)</BODY></HTML>", baseURL: NSURL(string: "about: blank"))
        }
        
        if (!NSThread.isMainThread())
        {
            createContextMainThread()
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), createContextMainThread)
        }
        return id;
    }
    
    class func useWKWebView(webView: WKWebView, options: [String: AnyObject] = Dictionary<String, AnyObject>(), delegate cb: NKScriptContextDelegate) -> Int
    {
        let id = NKJSContextFactory.sequenceNumber
        log("+Starting Renderer NodeKit Nitro JavaScript Engine E\(id)")
        
        var item = Dictionary<String, AnyObject>()
        NKJSContextFactory._contexts[id] = item;
        
        webView.navigationDelegate = NKWKWebViewDelegate(id: id, webView: webView, delegate: cb);
        
        item["WKWebView"] = webView
        
        objc_setAssociatedObject(webView, unsafeAddressOf(NKJSContextId), id, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // must call callback before page load as all plugins need to be initialized at this stage to secure channel
        cb.NKScriptEngineLoaded(webView)
        return id;
    }
}