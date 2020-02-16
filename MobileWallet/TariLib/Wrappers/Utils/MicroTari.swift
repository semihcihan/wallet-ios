//  MicroTari.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/15
	Using Swift 5.0
	Running on macOS 10.15

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

struct MicroTari {
    private static let CONVERSION = 1000000
    static let PRECISE_FRACTION_DIGITS = String(MicroTari.CONVERSION).count
    public static let ROUNDED_FRACTION_DIGITS = 2

    private static let defaultFormatter = NumberFormatter()
    private static let withOperatorFormatter = NumberFormatter()
    private static let preciseFormatter = NumberFormatter()
    private static let preciseWithOperatorFormatter = NumberFormatter()
    private static let editFormatter = NumberFormatter()

    public static var groupingSeparator: String {
        return defaultFormatter.groupingSeparator
    }

    public static var decimalSeparator: String {
        return defaultFormatter.decimalSeparator
    }

    var rawValue: UInt64

    var taris: Float {
        return Float(self.rawValue) / Float(MicroTari.CONVERSION)
    }

    var formatted: String {
        return MicroTari.defaultFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithOperator: String {
        return MicroTari.withOperatorFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithNegativeOperator: String {
        return MicroTari.withOperatorFormatter.string(from: NSNumber(value: self.taris * -1))!
    }

    var formattedPrecise: String {
        return MicroTari.preciseFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedPreciseWithOperator: String {
        return MicroTari.preciseWithOperatorFormatter.string(from: NSNumber(value: self.taris))!
    }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue

        MicroTari.defaultFormatter.numberStyle = .decimal
        MicroTari.defaultFormatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        MicroTari.defaultFormatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        MicroTari.defaultFormatter.negativePrefix = "-"

        MicroTari.withOperatorFormatter.numberStyle = .decimal
        MicroTari.withOperatorFormatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        MicroTari.withOperatorFormatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        MicroTari.withOperatorFormatter.positivePrefix = "+ "
        MicroTari.withOperatorFormatter.negativePrefix = "- "

        MicroTari.preciseFormatter.numberStyle = .decimal
        MicroTari.preciseFormatter.minimumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        MicroTari.preciseFormatter.maximumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        MicroTari.preciseFormatter.negativePrefix = "- "

        MicroTari.preciseWithOperatorFormatter.numberStyle = .decimal
        MicroTari.preciseWithOperatorFormatter.minimumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        MicroTari.preciseWithOperatorFormatter.maximumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        MicroTari.preciseWithOperatorFormatter.positivePrefix = "+ "
        MicroTari.preciseWithOperatorFormatter.negativePrefix = "- "

        MicroTari.editFormatter.numberStyle = .decimal
        MicroTari.editFormatter.minimumFractionDigits = 0
        MicroTari.editFormatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        MicroTari.editFormatter.negativePrefix = "-"
    }

    public mutating func setRawValue(_ value: UInt64) {
        rawValue = value * UInt64(MicroTari.CONVERSION)
    }

    public static func convertToNumber(_ number: String) -> NSNumber? {
        return defaultFormatter.number(from: number)
    }

    public static func convertToString(_ number: NSNumber, decimal: Int) -> String? {
        editFormatter.minimumFractionDigits = decimal
        return editFormatter.string(from: number)
    }
}
