//
//  DateHelper.swift
//  Pulser
//
//  Created by Tom Gardiner on 16/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation

struct DateComponentUnitFormatter {
	
	private struct DateComponentUnitFormat {
		let unit: Calendar.Component
		let pluralUnit: String
	}
	
	private let formats: [DateComponentUnitFormat] = [
		DateComponentUnitFormat(unit: .year, pluralUnit: "y"),
		DateComponentUnitFormat(unit: .weekOfYear, pluralUnit: "w"),
		DateComponentUnitFormat(unit: .day, pluralUnit: "d"),
		DateComponentUnitFormat(unit: .hour, pluralUnit: "h"),
		DateComponentUnitFormat(unit: .minute, pluralUnit: "m"),
		DateComponentUnitFormat(unit: .second, pluralUnit: "s"),
	]
	
	func string(forDateComponents dateComponents: DateComponents, useNumericDates: Bool) -> String {
		for format in self.formats {
			let unitValue: Int
			
			switch format.unit {
			case .year:
				unitValue = dateComponents.year ?? 0
			case .weekOfYear:
				unitValue = dateComponents.weekOfYear ?? 0
			case .day:
				unitValue = dateComponents.day ?? 0
			case .hour:
				unitValue = dateComponents.hour ?? 0
			case .minute:
				unitValue = dateComponents.minute ?? 0
			case .second:
				unitValue = dateComponents.second ?? 0
			default:
				assertionFailure("Date does not have required components")
				return ""
			}
			
			switch unitValue {
			case 1 ..< Int.max:
				return "\(unitValue)\(format.pluralUnit)"
			default:
				break
			}
		}
		
		return "0s"
	}
}

extension Date {
	
	func timeAgoSinceNow(useNumericDates: Bool = false) -> String {
		let calendar = Calendar.current
		let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .year, .second]
		let now = Date()
		let components = calendar.dateComponents(unitFlags, from: self, to: now)
		
		let formatter = DateComponentUnitFormatter()
		return formatter.string(forDateComponents: components, useNumericDates: useNumericDates)
	}
}
