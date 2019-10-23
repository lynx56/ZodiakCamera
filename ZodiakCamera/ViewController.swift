//
//  ViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 14/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    private var settings = Dictionary<Settings, Int>()
    
    @IBOutlet weak var joystickView: JoystickView!
    let url = URL(string: "http://188.242.14.235:81/videostream.cgi?loginuse=admin&amp;loginpas=123123")
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
        toolbarItems = [refresh]
        navigationController?.isToolbarHidden = false
        
        imagetask = URLSession.shared.dataTask(with: URL(string: "http://188.242.14.235:81/snapshot.cgi?user=admin&pwd=123123")!) { (data, response, error) in
            if let data = data {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
        
        webView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       //  webView.load(.init(url: url!))
       // readSetiings()
      //  createDisplayLink()
        
        joystickView.moveHandler = {
            self.userManipulate(command: "\(moveToCameraCommandConverter(direction: $0))")
        }
    }
    
    func createDisplayLink() {
        let displaylink = CADisplayLink(target: self,
                                        selector: #selector(step))
        
        displaylink.add(to: .current,
                        forMode: .default)
    }
    
    var imagetask: URLSessionDataTask?
    
    @objc func step(displaylink: CADisplayLink) {
        imageView.image = UIImage(data: try! Data(contentsOf: URL(string: "http://188.242.14.235:81/snapshot.cgi?user=admin&pwd=123123")!))
        
        imagetask?.resume()
    }
    
    func getUrl(with cgi: String) -> String {
        return "http://188.242.14.235:81/\(cgi)?loginuse=admin&amp;loginpas=123123"
    }
    
    func chageSettings(param: String, value: String) {
        var cgi =  getUrl(with: "camera_control.cgi")
        cgi += "&param=\(param)&value=\(value)"
        cgi += "&\(Date().stamp())"
    
        let url = URL(string: cgi)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(error)
        }
        
        task.resume()
    }
    
    func userManipulate(command: String) {
        var cgi = getUrl(with: "decoder_control.cgi");
        cgi += "&command=\(command)"
        cgi += "&onestep=0"
        cgi += "&\(Date().stamp())"
        
        let url = URL(string: cgi)!
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(error)
        }
        
        task.resume()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    func readSetiings() {
        let url = getUrl(with: "get_camera_params.cgi")
        let task = URLSession.shared.downloadTask(with: URL(string: url)!) { (file, response, error) in
            if let file = file {
                self.settings = try! String(contentsOf: file).parseCGI()
            }
        }
        
        task.resume()
    }
}


extension Date {
    func stamp() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000) + Int64(arc4random())
    }
}


extension String {
    func parseCGI()->Dictionary<Settings, Int> {
        var result = Dictionary<Settings, Int>()
        let components =
            self
                .removingAllWhitespaces()
                .replacingOccurrences(of: "var", with: "")
                .components(separatedBy: ";")
                .filter { !$0.isEmpty }
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            guard keyValue.count == 2 else { fatalError("Format is not supported") }
            if let key = keyValue.first?.removingAllWhitespaces(),
                let value = keyValue.last?.removingAllWhitespaces() {
                result[Settings(rawValue: key)!] = Int(value)!
            }
        }
        
        return result
    }
    
    func removingAllWhitespaces() -> String {
        return removingCharacters(from: .whitespacesAndNewlines)
    }
    
    func removingCharacters(from set: CharacterSet) -> String {
        var newString = self
        newString.removeAll { char -> Bool in
            guard let scalar = char.unicodeScalars.first else { return false }
            return set.contains(scalar)
        }
        return newString
    }
}

enum Settings: String {
    case Resolution = "resolution"
    case Mode = "mode"
    case OSDEnable = "OSDEnable"
    case ResolutionSub = "resolutionsub"
    case SubEncFramerate = "sub_enc_framerate"
    case Bright = "vbright"
    case Saturation = "vsaturation"
    case bitrate = "enc_bitrate"
    case Hue = "vhue"
    case Flip = "flip"
    case IRcut = "ircut"
    case Speed = "speed"
    case Framerate = "enc_framerate"
    case Contrast = "vcontrast"
}

func moveToCameraCommandConverter(direction: JoystickView.Event) -> Int {
    switch direction {
    case .stop: return 1
    case .move(let direction):
        switch direction {
        case .down: return 2
        case .downleft: return 92
        case .downright: return 93
        case .left: return 4
        case .right: return 6
        case .up: return 0
        case .upleft: return 90
        case .upright: return 91
        }
    }
}
