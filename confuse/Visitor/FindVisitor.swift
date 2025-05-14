//
//  FindVisitor.swift
//  confuse
//
//  Created by ppyupp on 2024/10/19.
//

import Foundation
import SwiftSyntax

public class FindVisitor: BaseVisitor {
	var optionalBindingConditionSyntaxList = [OptionalBindingConditionSyntax]()
	var forStmtSyntaxList = [ForStmtSyntax]()

	override public func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
		self.optionalBindingConditionSyntaxList.append(node)
		return .visitChildren
	}

	override public func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
		self.forStmtSyntaxList.append(node)
		return .visitChildren
	}
}
