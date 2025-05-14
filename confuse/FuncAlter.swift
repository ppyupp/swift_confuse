//
//  FuncAlter.swift
//  confuse
//
//  Created by ppyupp on 2024/9/8.
//

import Foundation
import SwiftSyntax

class FuncAlter {
	var className: String
	var funcName: String
	
	init(className: String, funcName: String) {
		self.className = className
		self.funcName = funcName
	}
	
	func run() {
		guard let classUnit = kGlobal.classList.first(where: { c in
			c.name == self.className
		}) else {
			return
		}
		
		guard let funcUnit = classUnit.funcList.first(where: { f in
			f.name == self.funcName
		}) else{
			return
		}
				
		classUnit.file.sourceSyntax = FuncRewriter(name: self.funcName).visit(classUnit.file.sourceSyntax)
				
		/*
		for f in classUnit.funcList{
			print(f.name)
			
			classUnit.file.sourceSyntax = FunctionRewriter(name: "c").visit(classUnit.file.sourceSyntax)
		}
		 */
	}
	
	func doFunc(){
		
	}
}
