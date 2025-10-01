import SwiftUI

public enum AppColors {
    // Corporate palette (brand colors)
    public static let corpPrimary = Color(red: 11/255, green: 145/255, blue: 219/255)   // HEX 0b91db Pantone 299 U
    public static let corpSecondary = Color(red: 0/255, green: 110/255, blue: 183/255) // HEX 006eb7 Pantone 660 CP
    public static let corpGray = Color(red: 188/255, green: 188/255, blue: 188/255)    // HEX bcbcbc Pantone Cool Gray 5 UP
    public static let corpDarkGray = Color(red: 65/255, green: 73/255, blue: 76/255)   // HEX 41494c Pantone 5463 U

    public static let corpGreen = Color(red: 96/255, green: 186/255, blue: 151/255)    // HEX 60ba97 Pantone 3395 UP
    public static let corpYellow = Color(red: 243/255, green: 190/255, blue: 93/255)   // HEX f3be5d Pantone 142 UP
    public static let corpRed = Color(red: 244/255, green: 100/255, blue: 77/255)      // HEX f4644d Pantone 172 U
    
    // Basic colors
    public static let overlayLight = Color.white.opacity(0.05)
    public static let overlayDark  = Color.black.opacity(0.25)
}
