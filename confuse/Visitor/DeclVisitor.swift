//
//  visitor.swift
//  confuse
//
//  Created by ppyupp on 2024/7/12.
//

import Foundation
import SwiftSyntax

public class DeclVisitor: BaseVisitor {
	
	var classDeclList = [ClassDeclSyntax]()
	
	override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		
		self.classDeclList.append(node)
		
		return .visitChildren
	}
	
	override public func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
		if node.baseName.text != "name" {
			return .visitChildren
		}
		
		// print("xxx", node.baseName.text, self.global.findType(declReferenceExprSyntax: node))
		
		// dump(node)
		// self.global.findType(node: node)
		
		return .visitChildren
	}
	
	override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
		// dump(node.keyPathInParent)
		//print(node.id)
		
		/*
		if let memberAccessExpr = node.calledExpression.as(MemberAccessExprSyntax.self) {
			let ptype = self.global.findType(exprSyntax: memberAccessExpr.base)
			//print("tttt", ptype)
		}
		 */
		
		/*
		 if node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "getNickname" || node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "getNickname" {
		 	// 可能有多个符合的情况
		 	// 这时候, 谁的形参少, 谁符合
		 	for c in self.global.classList {
		 		for f in c.functionList {
		 			let r = f.isEq(call: node)
		 			if r {
		 				print("is eq!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		 			} else {
		 				print("not eq")
		 			}
		 		}
		 	}
		 }
		  */
		
		return .visitChildren
	}
	
	
}
