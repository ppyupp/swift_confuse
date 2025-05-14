//
//  FuncRewriter.swift
//  confuse
//
//  Created by ppyupp on 2024/9/8.
//

import Foundation
import SwiftSyntax

public class FuncRewriter: BaseRewriter {
	var name = ""
	
	init(name: String = "") {
		self.name = name
	}
	
	override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
		var newNode = node
		
		newNode = self.modifyFunctionParamName(node)
		
		return super.visit(newNode)
	}
	
	func modifyFunctionParamName(_ funcDecl: FunctionDeclSyntax) -> FunctionDeclSyntax {
		if funcDecl.name.text != self.name {
			return funcDecl
		}
		
		var newFunc = funcDecl
		
		var newName = kGlobal.buildName(name: funcDecl.name.text)
		
		newFunc.name.tokenKind = .identifier(newName)
		
		var oldNames = [String]()
		var newNames = [String]()
		
		// 修改签名
		newFunc.signature.parameterClause.parameters = FunctionParameterListSyntax(funcDecl.signature.parameterClause.parameters.map { p in
			var newP = p
						
			if p.firstName.tokenKind != .wildcard {
				let name = kGlobal.buildName(name: p.firstName.text)
				
				newP.firstName.tokenKind = .identifier(name)
				
				oldNames.append(p.firstName.text)
				newNames.append(name)

			} else if p.secondName != nil {
				let name = kGlobal.buildName(name: p.secondName!.text)
				
				newP.secondName?.tokenKind = .identifier(name)
				
				oldNames.append(p.secondName!.text)
				newNames.append(name)
			}
			
			return newP
		})
		
		if newFunc.body != nil {
			for (i, old) in oldNames.enumerated() {
				let to = newNames[i]
				
				newFunc.body!.statements = self.modifyCodeBlockVariable(blockItemList: newFunc.body!.statements, varName: old, toName: to)
			}
		}

		return newFunc
	}
}
