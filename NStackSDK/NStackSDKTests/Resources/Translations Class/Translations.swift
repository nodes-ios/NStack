//// ----------------------------------------------------------------------
//// File generated by NStack Translations Generator.
////
//// Last update: 20/02/16 22:46:43 GMT+1
////
//// Copyright (c) 2016 Nodes ApS
////
//// Permission is hereby granted, free of charge, to any person obtaining
//// a copy of this software and associated documentation files (the
//// "Software"), to deal in the Software without restriction, including
//// without limitation the rights to use, copy, modify, merge, publish,
//// distribute, sublicense, and/or sell copies of the Software, and to
//// permit persons to whom the Software is furnished to do so, subject to
//// the following conditions:
////
//// The above copyright notice and this permission notice shall be
//// included in all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//// ----------------------------------------------------------------------
//
//import Foundation
////import Serpent
//import NStackSDK
//
//public var tr: Translations {
//    get {
//        guard let manager = NStack.sharedInstance.translationsManager else {
//            return Translations()
//        }
//        return manager.translationsObject
//    }
//}
//
//public struct Translations: Translatable {
//    var defaultSection = DefaultSection() //<-default
//
//    public struct DefaultSection {
//        var successKey = ""
//    }
//}
//
//extension Translations: Serializable {
//    public init(dictionary: NSDictionary?) {
//        defaultSection <== (self, dictionary, "default")
//    }
//
//    public func encodableRepresentation() -> NSCoding {
//        let dict = NSMutableDictionary()
//        (dict, "default") <== defaultSection
//        return dict
//    }
//}
//
//extension Translations.DefaultSection: Serializable {
//    public init(dictionary: NSDictionary?) {
//        successKey <== (self, dictionary, "successKey")
//    }
//
//    public func encodableRepresentation() -> NSCoding {
//        let dict = NSMutableDictionary()
//        (dict, "successKey") <== successKey
//        return dict
//    }
//}
