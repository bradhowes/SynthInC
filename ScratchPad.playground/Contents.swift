//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let phraseColorAlpha = CGFloat(1.0)
let stops = [0.0, 0.33, 0.66, 1.0]

let g = stops

struct ComponentGenerator : Sequence, IteratorProtocol {
    typealias Element = Double
    var index = 0

    mutating func next() -> ComponentGenerator.Element? {
        guard index < stops.count else {
            index = 0
            return nil
        }

        defer { index += 1 }
        return stops[index]
    }
}

struct ColorGenerator : Sequence, IteratorProtocol
{
    typealias Element = UIColor?

    var redGen = ComponentGenerator()
    var greenGen = ComponentGenerator()
    var blueGen = ComponentGenerator()

    var red: Double?
    var green: Double?

    init() {
        self.red = redGen.next()
        self.green = greenGen.next()
    }

    mutating func next() -> ColorGenerator.Element? {
        guard self.red != nil else { return nil }

        var blue = blueGen.next()
        if blue == nil {
            blue = blueGen.next()
            green = greenGen.next()
            if green == nil {
                green = greenGen.next()
                red = redGen.next()
                if red == nil {
                    return nil
                }
            }
        }
        
        return UIColor.init(red: CGFloat(red!), green: CGFloat(green!), blue: CGFloat(blue!), alpha: phraseColorAlpha)
    }
}

// HSV values in [0..1[
// returns [r, g, b] values from 0 to 255

func hsv_to_rgb(h: CGFloat, s: CGFloat, v: CGFloat) -> UIColor {

    // h_i = (h*6).to_i
    let hueIndex = Int(h * 6)

    // f = h*6 - h_i
    let f: CGFloat = h * 6.0 - CGFloat(hueIndex)

    // p = v * (1 - s)
    let p: CGFloat = v * (1.0 - s)

    // q = v * (1 - f*s)
    let q: CGFloat = v * (1.0 - f * s)
    
    // t = v * (1 - (1 - f) * s)
    let t: CGFloat = v * (1.0 - (1.0 - f) * s)
    
    switch hueIndex {
    // r, g, b = v, t, p if h_i==0
    case 0: return UIColor(red: v, green: t, blue: p, alpha: 1.0)
    // r, g, b = q, v, p if h_i==1
    case 1: return UIColor(red: q, green: v, blue: p, alpha: 1.0)
    // r, g, b = p, v, t if h_i==2
    case 2: return UIColor(red: p, green: v, blue: t, alpha: 1.0)
    // r, g, b = p, q, v if h_i==3
    case 3: return UIColor(red: p, green: q, blue: v, alpha: 1.0)
    // r, g, b = t, p, v if h_i==4
    case 4: return UIColor(red: t, green: p, blue: v, alpha: 1.0)
    // r, g, b = v, p, q if h_i==5
    default: return UIColor(red: v, green: p, blue: q, alpha: 1.0)
    }
}


// { hsv_to_rgb(rand, 0.5, 0.95) }

let colors: [UIColor] = [
    hsv_to_rgb(h: 0.0, s: 0.5, v: 0.95),
    hsv_to_rgb(h: 0.2, s: 0.5, v: 0.95),
    hsv_to_rgb(h: 0.4, s: 0.5, v: 0.95),
    hsv_to_rgb(h: 0.6, s: 0.5, v: 0.95),
    hsv_to_rgb(h: 0.8, s: 0.5, v: 0.95),
    hsv_to_rgb(h: 1.0, s: 0.5, v: 0.95),
]


