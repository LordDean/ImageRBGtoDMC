//
//  ImageColourList.swift
//  Image Testing
//
//  Created by Dean Mollica on 18/1/18.
//  Copyright © 2018 Dean Mollica. All rights reserved.
//

import Foundation

struct ImageColour {
    let x:Int
    let y:Int
    let r:Int
    let g:Int
    let b:Int
    
    func colourArray() -> [Int] {
        return [r, g, b]
    }
}
