//
//  ClassVariableRewriter.swift
//  confuse
//
//  Created by ppyupp on 2024/9/27.
//

import Foundation
import SwiftSyntax

public class ClassVariableRewriter: BaseRewriter {
	var fromName = ""
	var className = ""
	var file: FileUnit

	init(fromName: String = "", className: String, file:FileUnit) {
		self.fromName = fromName
		self.className = className
		self.file = file
	}
	
	override public func visit(_ token: DeclReferenceExprSyntax) -> ExprSyntax {
		var newToken = token
		
		if token.baseName.text == self.fromName {
			// print("find parent begin", self.fromName)
			
			let parentName = kGlobal.findParent(exprSyntax: ExprSyntax(token), currentFile: self.file)
			
			// print("find parent result", self.fromName, parentName, self.className)
			
			if parentName != nil && parentName! == self.className {
				// print("find parent modify", self.fromName, parentName, self.className)
				newToken.baseName.tokenKind = .identifier(kGlobal.buildName(name: self.fromName))
			}
		}
		
		return super.visit(newToken)
	}
}
