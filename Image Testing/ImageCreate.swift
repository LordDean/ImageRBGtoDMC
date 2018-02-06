//
//  ImageCreate.swift
//  Image Testing
//
//  Created by Dean Mollica on 20/1/18.
//  Copyright © 2018 Dean Mollica. All rights reserved.
//

import Cocoa
import CoreGraphics

public struct PixelData {
    var r:UInt8
    var g:UInt8
    var b:UInt8
    let a:UInt8 = 255
}

private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

public func imageFromRGBA32Bitmap(pixels:[PixelData], width:Int, height:Int)->NSImage {
    let bitsPerComponent = 8
    let bitsPerPixel = bitsPerComponent * 4
    
    assert(pixels.count == width * height)
    
    var data = pixels // Copy to mutable []
    let providerRef = CGDataProvider(
        data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size)
    )
    let cgim = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: width * 4, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    return NSImage(cgImage: cgim!, size: NSZeroSize)
}
