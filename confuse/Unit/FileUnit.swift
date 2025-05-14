//
//  FileUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/9/3.
//

import Foundation
import SwiftSyntax

class FileUnit {
	var filePath: URL!

	var sourceSyntax: SourceFileSyntax

	var classList = [ClassUnit]()
	var extensionList = [ExtensionUnit]()
	var funcList = [FuncUnit]()
	var varList = [VarUnit]()

	var optionalBindingConditionSyntaxList = [String: [OptionalBindingConditionSyntax]]()
	var forStmtSyntaxList = [String: [ForStmtSyntax]]()
	var variableDeclSyntaxList = [String: [VariableDeclSyntax]]()

	init(filePath: URL, sourceSyntax: SourceFileSyntax) {
		self.filePath = filePath
		self.sourceSyntax = sourceSyntax
	}

	func ready() {
		for c in self.classList {
			c.file = self
		}

		for e in self.extensionList {
			e.file = self
		}
	}

	func getLine(node: Syntax) -> Int {
		node.startLocation(converter: SourceLocationConverter(file: "", tree: self.sourceSyntax)).line
	}

	func getVariableDeclSyntaxList(scopePath: String) -> [VariableDeclSyntax]? {
		
		if let l = self.variableDeclSyntaxList[scopePath] {
			return l
		}
		
		return nil
	}
	
	func getOptionalBindingConditionSyntaxList(scopePath: String) -> [OptionalBindingConditionSyntax]? {
		
		if let l = self.optionalBindingConditionSyntaxList[scopePath] {
			return l
		}
		
		return nil
	}
	
	func getForStmtSyntaxList(scopePath: String) -> [ForStmtSyntax]? {
		
		if let l = self.forStmtSyntaxList[scopePath] {
			return l
		}
		
		return nil
	}
}
