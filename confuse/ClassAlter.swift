//
//  ClassAlter.swift
//  confuse
//
//  Created by ppyupp on 2024/9/25.
//

import Foundation
import SwiftSyntax

class ClassAlter {
	var className: String
	
	init(className: String) {
		self.className = className
	}
	
	func run() {
		guard let classUnit = kGlobal.classList.first(where: { c in
			c.name == self.className
		}) else {
			print("ClassAlter Fail, ", self.className, " not found")
			return
		}
		
		classUnit.file.sourceSyntax = ClassRewriter(className: self.className).visit(classUnit.file.sourceSyntax)
		
		for e in kGlobal.extensionList {
			if e.name == self.className {
				e.file.sourceSyntax = ExtensionRewriter(name: self.className).visit(e.file.sourceSyntax)
			}
		}
		
		let startTime = ProcessInfo.processInfo.systemUptime
		for f in kGlobal.fileList {
			f.sourceSyntax = CallRewriter(className: self.className, file: f).visit(f.sourceSyntax)
		}
		let endTime = ProcessInfo.processInfo.systemUptime
		let elapsedTime = endTime - startTime
		
		print("call rewrite 执行时间: \(elapsedTime) 秒")


	}
	
	func doFunc() {}
}
