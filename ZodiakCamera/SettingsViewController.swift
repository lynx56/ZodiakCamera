//
//  SettingsViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 15/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Eureka
import UIKit

class SettingsViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section("Настройки доступа")
            <<< TextRow() { row in
                row.title = "Логин"
                row.placeholder = "admin"
            }
            <<< PasswordRow() { row in
                row.title = "Пароль"
                row.placeholder = "123123"
            }
            +++ Section("Адрес")
            <<< URLRow() { row in
                row.title = "Хост"
                row.placeholder = "192.168.1.1"
            }
            <<< IntRow() { row in
                row.title = "Порт"
                row.placeholder = "81"
            }
        }
}



/*
 +++ Section ("Изображение")
 <<< SegmentedRow() { row in
 row.title = "Разрешение"
 row.options = ["640x480, 320x240"]
 }
 <<< SliderRow() { row in
 row.title = "Brightness"
 row.steps = 100
 }
 <<< SliderRow() { row in
 row.title = "Contrast"
 row.steps = 100
 }
 <<< SliderRow() { row in
 row.title = "Saturation" //насыщенность
 row.steps = 100
 }
 <<< SliderRow() { row in
 row.title = "Hue" //тон
 row.steps = 100
 }
 <<< () {
 */
