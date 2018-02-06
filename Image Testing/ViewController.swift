//
//  ViewController.swift
//  Image Testing
//
//  Created by Dean Mollica on 15/1/18.
//  Copyright © 2018 Dean Mollica. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    //MARK: IBOutlets
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var resultImageView: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var colourPaletteSelection: NSSegmentedControl!
    @IBOutlet weak var fileNameLabel: NSTextField!
    
    //MARK: Variables
    var threadColourList = [ThreadColour]()
    var imageColourList = [ImageColour]()
    var convertedColours = [[Int]()]
    var imageSize = NSSize()
    var threadFileContents: String?
    
//    let threadPalette = ["168", "310", "311", "317", "318", "319", "321", "350", "444", "550", "552", "604", "700", "721", "738", "740", "741", "742", "780", "783", "815", "820", "825", "827", "890", "907", "938", "943", "946", "995", "3765", "3801", "3821", "3822", "3827", "3853", "B5200"]
    
    let DEBUG = true
    
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        threadColourList = createColourList(fromString: threadColourData)
        
        if DEBUG { print("Total Thread Colours: \(threadColourList.count)") }
        
        let image = Bundle.main.image(forResource: NSImage.Name(rawValue: "botw"))
        
        let result = createImageListAndSize(forImage: image!, withImageView: imageView)
        imageColourList = result.0
        imageSize = result.1
        
        if DEBUG { print("   Total Pixel Count: \(imageColourList.count)") }
         
    }
    
    //MARK: Functions
    func createColourList(fromString colourData : String) -> [ThreadColour] {
        let rows = colourData.split(separator: "\n")
        var returnArray = [ThreadColour]()
        for row in rows {
            let items = row.split(separator: ",")
            returnArray.append(ThreadColour(thread: String(items[0]), r: Int(items[1])!, g: Int(items[2])!, b: Int(items[3])!, description: String(items[4])))
        }
        return returnArray
    }
    
    func createImageListAndSize(forImage image : NSImage, withImageView destImageView : NSImageView) -> ([ImageColour], NSSize) {
        destImageView.image = image
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        let imageSize = image.size
        var returnArray = [ImageColour]()
        for yIndex in 0 ..< Int(imageSize.height) {
            for xIndex in 0 ..< Int(imageSize.width) {
                if let pixel = imageRep?.colorAt(x: xIndex, y: yIndex) {
                    returnArray.append(ImageColour(x: Int(xIndex), y: Int(yIndex), r: colourCGFloatToInt(pixel.redComponent), g: colourCGFloatToInt(pixel.greenComponent), b: colourCGFloatToInt(pixel.blueComponent)))
                }
            }
        }
        
        return (returnArray, imageSize)
    }
    
    func colourCGFloatToInt(_ value : CGFloat) -> Int {
        return Int(value * 255)
    }
    
    func uniqueImageColours(_ fullList: [ImageColour]) -> [[Int]] {
        var colourArray = [[Int]()]
        for pixel in fullList {
            colourArray.append(pixel.colourArray())
        }
        
        var uniqueValues = [[Int]()]
        for colour in colourArray {
            if (uniqueValues.contains { $0 == colour }) {
                continue
            } else {
                uniqueValues.append(colour)
            }
        }
        
        return uniqueValues
    }
    
    func getColourDistance(firstColour: [Int], secondColour: [Int]) -> Int {
        let rDistance = firstColour[0] - secondColour[0]
        let gDistance = firstColour[1] - secondColour[1]
        let bDistance = firstColour[2] - secondColour[2]
        
        return rDistance * rDistance + gDistance * gDistance + bDistance * bDistance
    }
    
    func getClosestThreadColour(threadColours: [ThreadColour], imageColour: [Int]) -> ThreadColour {
        var closestColour: ThreadColour?
        var lowestDistance = 200000
        
        for colour in threadColours {
            let distance = getColourDistance(firstColour: imageColour, secondColour: colour.colourArray())
            
            if distance == 0 {
                closestColour = colour
                break
            }
            
            if distance < lowestDistance {
                lowestDistance = distance
                closestColour = colour
            }
        }
        return closestColour!
    }
    
    func createReducedThreadPalette(fromList fullList: [ThreadColour], withThreadNumbers numbers : [String]) -> [ThreadColour] {
        var returnArray = [ThreadColour]()
        for number in numbers {
            for thread in fullList {
                if thread.thread == number {
                    returnArray.append(thread)
                    continue
                }
            }
        }
        
        if returnArray.count == 0 {
            print("Invalid Thread File")
            returnArray = fullList
            colourPaletteSelection.selectedSegment = 0
            colourPaletteSelection.setEnabled(false, forSegment: 1)
        }
        
        return returnArray
    }
    
    func createThreadList(fromFileContents contents: String) -> [String] {
        let splitFile = contents.split(separator: "\n")
        var returnList = [String]()
        for item in splitFile {
            returnList += [String(item)]
        }
        
        return returnList
    }
    
    //MARK: IBActions

    @IBAction func processButtonPressed(_ sender: Any) {
        if DEBUG { print("Processing...") }
        resultImageView.isHidden = true
        progressIndicator.startAnimation(self)
//        let chosenColourList = colourPaletteSelection.selectedSegment == 0 ? threadColourList : createReducedThreadPalette(fromList: threadColourList, withThreadNumbers: threadPalette)
        var chosenColourList: [ThreadColour]
        if colourPaletteSelection.selectedSegment == 0 {
            chosenColourList = threadColourList
        } else {
            if let file = threadFileContents {
                var colourList = [String]()
                for item in file.split(separator: "\n") {
                    colourList += [String(item)]
                }
                chosenColourList = createReducedThreadPalette(fromList: threadColourList, withThreadNumbers: colourList)
            } else {
                colourPaletteSelection.selectedSegment = 0
                chosenColourList = threadColourList
            }
        }
        
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        var pixelData = [PixelData]()
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            for pixel in self.imageColourList {
                let closestColour = self.getClosestThreadColour(threadColours: chosenColourList, imageColour: pixel.colourArray())
                pixelData.append(PixelData(r: UInt8(closestColour.r), g: UInt8(closestColour.g), b: UInt8(closestColour.b)))
            }
            
            let image = imageFromRGBA32Bitmap(pixels: pixelData, width: width, height: height)
            
            DispatchQueue.main.async { [unowned self] in
                self.resultImageView.image = image
                self.progressIndicator.stopAnimation(self)
                self.resultImageView.isHidden = false
            }
            
        }
        
    }
    
    @IBAction func selectThreadFile(_ sender: Any) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { [unowned self] (result) in
            if result == NSApplication.ModalResponse.OK {
                if self.DEBUG { print("okay") }
                if let url = panel.url {
                    if self.DEBUG { print(url) }
                    
                    do {
                        self.threadFileContents = try String(contentsOfFile: url.path)
                        self.fileNameLabel.stringValue = url.lastPathComponent
                        self.colourPaletteSelection.setEnabled(true, forSegment: 1)
                        self.colourPaletteSelection.selectedSegment = 1
                        
                    } catch let error as NSError {
                        print("Error reading file: " + error.localizedDescription)
                    }
                }
                
            }
        }

    }


}

