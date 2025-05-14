//
//  VariableRewriter.swift
//  confuse
//
//  Created by ppyupp on 2024/7/19.
//

import SwiftSyntax

public class VariableRewriter: BaseRewriter {
	var fromName = ""
	var toName = ""

	init(fromName: String = "", toName: String) {
		self.fromName = fromName
		self.toName = toName
	}
	
	override public func visit(_ token: DeclReferenceExprSyntax) -> ExprSyntax {
		var newToken = token
		
		if let memberAccessExpr = token.parent?.as(MemberAccessExprSyntax.self) {
			// xx.name的xx
			if memberAccessExpr.base?.id == token.id {
				if token.baseName.text == self.fromName {
					newToken.baseName.tokenKind = .identifier(self.toName)
				}
			}
			
		} else {
			if token.baseName.text == self.fromName {
				newToken.baseName.tokenKind = .identifier(self.toName)
			}
		}
		
		return super.visit(newToken)
	}
	
	/*
	 override public func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
	 	var newNode = node
		
	 	// 闭包
	 	if node.trailingClosure != nil{
	 		newNode.trailingClosure?.statements = self.modifyCodeBLockVariable(blockItemList: node.trailingClosure!.statements, varName: self.name)
	 	}
		
	 	return super.visit(newNode)
	 }
	  */
}
