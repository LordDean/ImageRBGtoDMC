//
//  ColourList.swift
//  Image Testing
//
//  Created by Dean Mollica on 16/1/18.
//  Copyright © 2018 Dean Mollica. All rights reserved.
//

import Foundation

struct ThreadColour {
    let thread:String
    let r:Int
    let g:Int
    let b:Int
    let description:String
    
    func colourArray() -> [Int] {
        return [r, g, b]
    }
}
