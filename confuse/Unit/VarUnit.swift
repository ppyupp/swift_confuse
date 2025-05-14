//
//  VarUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/9/3.
//

import Foundation
import SwiftSyntax

class VarUnit {
	weak var file: FileUnit!

	var name: String
	var varDecl: VariableDeclSyntax?
	weak var parentClass: ClassUnit?

	fileprivate var type: String?

	init(name: String, parentClass: ClassUnit? = nil) {
		self.name = name
		self.parentClass = parentClass
	}

	func getType() -> String? {
		
		if self.type != nil{
			return self.type
		}
		
		self.type = kGlobal.findVariableType(variableDeclSyntax: self.varDecl!, currentFile: self.file)
		
		return self.type
	}
}
