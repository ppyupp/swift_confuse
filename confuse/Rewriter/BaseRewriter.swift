//
//  BaseRewriter.swift
//  confuse
//
//  Created by ppyupp on 2024/7/20.
//

import Foundation
import SwiftSyntax

public class BaseRewriter: SyntaxRewriter {
	
	func modifyInitializer(_ initDecl: InitializerDeclSyntax) -> InitializerDeclSyntax {
		var newInit = initDecl
				
		var oldNames = [String]()
		var newNames = [String]()
	
		// 修改签名, 修改形参名字
		newInit.signature.parameterClause.parameters = FunctionParameterListSyntax(initDecl.signature.parameterClause.parameters.map { p in
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
		
		
		if newInit.body != nil {
			for (i, old) in oldNames.enumerated() {
				let to = newNames[i]
				
				newInit.body!.statements = self.modifyCodeBlockVariable(blockItemList: newInit.body!.statements, varName: old, toName: to)
			}
		}
				
		return newInit
	}
	
	func modifyFunction(_ funcDecl: FunctionDeclSyntax) -> FunctionDeclSyntax {
		var newFunc = funcDecl
		
		newFunc.name.tokenKind = .identifier(kGlobal.buildName(name: funcDecl.name.text))
		
		var oldNames = [String]()
		var newNames = [String]()
		
		if funcDecl.name.text == "receive" {
			//kDebug = true
			//print("=========== modify function ===========")
		}
		
		// 修改签名, 修改形参名字
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
		
		if kDebug {
			// dump(newFunc.body)
		}
		
		if newFunc.body != nil {
			for (i, old) in oldNames.enumerated() {
				let to = newNames[i]
				
				newFunc.body!.statements = self.modifyCodeBlockVariable(blockItemList: newFunc.body!.statements, varName: old, toName: to)
			}
		}
		
		kDebug = false
		
		return newFunc
	}
	
	func modifyCodeBlockVariable(ifExprSyntax: IfExprSyntax, varName: String, toName: String) -> IfExprSyntax {
		var newIf = ifExprSyntax
		
		newIf.conditions = VariableRewriter(fromName: varName, toName: toName).visit(newIf.conditions)
		newIf.body.statements = self.modifyCodeBlockVariable(blockItemList: newIf.body.statements, varName: varName, toName: toName)
		
		if var elseBlock = newIf.elseBody?.as(CodeBlockSyntax.self) {
			elseBlock.statements = self.modifyCodeBlockVariable(blockItemList: elseBlock.statements, varName: varName, toName: toName)
			
			newIf.elseBody = IfExprSyntax.ElseBody(elseBlock)
		} else if var elseIfBlock = newIf.elseBody?.as(IfExprSyntax.self) {
			newIf.elseBody = IfExprSyntax.ElseBody(self.modifyCodeBlockVariable(ifExprSyntax: elseIfBlock, varName: varName, toName: toName))
		}
		
		return newIf
	}
	
	func modifyCodeBlockVariable(expressionStmtSyntax: ExpressionStmtSyntax, varName: String, toName: String) -> ExpressionStmtSyntax {
		var newStmt = expressionStmtSyntax
		
		if var ifExpr = expressionStmtSyntax.expression.as(IfExprSyntax.self) {
			newStmt.expression = ExprSyntax(self.modifyCodeBlockVariable(ifExprSyntax: ifExpr, varName: varName, toName: toName))
		} else if var switchExpr = expressionStmtSyntax.expression.as(SwitchExprSyntax.self) {
			switchExpr.subject = VariableRewriter(fromName: varName, toName: toName).visit(switchExpr.subject)
			
			switchExpr.cases = SwitchCaseListSyntax(switchExpr.cases.map { c in
				
				if var newCase = c.as(SwitchCaseSyntax.self) {
					newCase.statements = self.modifyCodeBlockVariable(blockItemList: newCase.statements, varName: varName, toName: toName)
					
					return SwitchCaseListSyntax.Element(newCase)
				}
				
				return c
				
			})
			
			newStmt.expression = ExprSyntax(switchExpr)
		}
		
		return newStmt
	}

	// 修改代码块里面的变量
	func modifyCodeBlockVariable(blockItemList: CodeBlockItemListSyntax, varName: String, toName: String) -> CodeBlockItemListSyntax {
		var newBlockItemList = blockItemList
		
		var stop = false
		newBlockItemList = CodeBlockItemListSyntax(blockItemList.map { itemSyntax in
			
			if stop {
				return itemSyntax
			}
			
			var newItemSyntax = itemSyntax
			
			if let stmt = itemSyntax.item.as(ExpressionStmtSyntax.self) {
				newItemSyntax.item = CodeBlockItemSyntax.Item(self.modifyCodeBlockVariable(expressionStmtSyntax: stmt, varName: varName, toName: toName))
			} else if let stmt = itemSyntax.item.as(ForStmtSyntax.self) {
				var newStmt = stmt
				
				if let sequenceExpr = stmt.sequence.as(SequenceExprSyntax.self) {
					newStmt.sequence = VariableRewriter(fromName: varName, toName: toName).visit(sequenceExpr)
				} else if let d = stmt.sequence.as(DeclReferenceExprSyntax.self) {
					newStmt.sequence = VariableRewriter(fromName: varName, toName: toName).visit(d)
				}
				
				newStmt.body.statements = self.modifyCodeBlockVariable(blockItemList: stmt.body.statements, varName: varName, toName: toName)
				
				newItemSyntax.item = CodeBlockItemSyntax.Item(newStmt)
			} else if let stmt = itemSyntax.item.as(SequenceExprSyntax.self) {
				var newStmt = stmt
				
				newStmt.elements = ExprListSyntax(stmt.elements.map { e in
					if var call = e.as(FunctionCallExprSyntax.self), call.trailingClosure != nil {
						// 闭包调用
						if !call.trailingClosure!.hasParameter(name: varName) {
							// params 不包含同名变量才修改
							call.trailingClosure = self.modifyClosureCallVariable(closure: call.trailingClosure!, varName: varName, toName: toName)
						}
						return ExprSyntax(call)
					} else {
						return VariableRewriter(fromName: varName, toName: toName).visit(e)
					}
				})
				
				newItemSyntax.item = CodeBlockItemSyntax.Item(newStmt)

			} else if let varDecl = itemSyntax.item.as(VariableDeclSyntax.self) {
				// 碰到了重新定义的同名变量, 结束往下的修改
				if let binding = varDecl.bindings.first, binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == varName {
					var newBinding = binding
					if binding.initializer != nil {
						newBinding.initializer = VariableRewriter(fromName: varName, toName: toName).visit(binding.initializer!)
					}
					
					var newVarDecl = varDecl
					newVarDecl.bindings = PatternBindingListSyntax([newBinding])
					
					newItemSyntax.item = CodeBlockItemSyntax.Item(newVarDecl)
					
					stop = true
				} else {
					newItemSyntax = VariableRewriter(fromName: varName, toName: toName).visit(itemSyntax)
				}
			} else if let stmt = itemSyntax.item.as(FunctionCallExprSyntax.self) {
				var newStmt = stmt
				
				newStmt.arguments = VariableRewriter(fromName: varName, toName: toName).visit(stmt.arguments)
				newStmt.calledExpression = VariableRewriter(fromName: varName, toName: toName).visit(stmt.calledExpression)
				
				if newStmt.trailingClosure != nil {
					if !newStmt.trailingClosure!.hasParameter(name: varName) {
						// params 不包含同名变量才修改
						newStmt.trailingClosure = self.modifyClosureCallVariable(closure: newStmt.trailingClosure!, varName: varName, toName: toName)
					}
				}

				// print(newStmt)
				
				newItemSyntax.item = CodeBlockItemSyntax.Item(newStmt)

			} else {
				newItemSyntax = VariableRewriter(fromName: varName, toName: toName).visit(itemSyntax)
			}
			
			return newItemSyntax
		})
													  
		return newBlockItemList
	}
	
	func modifyClosureCallVariable(closure: ClosureExprSyntax, varName: String, toName: String) -> ClosureExprSyntax {
		var newClosure = closure
		
		if closure.signature != nil, closure.signature?.capture != nil {
			newClosure.signature?.capture = VariableRewriter(fromName: varName, toName: toName).visit(closure.signature!.capture!)
		}
		
		newClosure.statements = self.modifyCodeBlockVariable(blockItemList: closure.statements, varName: varName, toName: toName)
		
		return newClosure
	}
	
	// 修改代码块里面的self变量
	func modifyCodeBlockSelfVariable(blockItemList: CodeBlockItemListSyntax, varName: String, className: String, currentFile: FileUnit) -> CodeBlockItemListSyntax {
		var newBlockItemList = blockItemList
		let toName = kGlobal.buildName(name: varName)
		
		var stop = false
		newBlockItemList = CodeBlockItemListSyntax(blockItemList.map { item in
			
			if stop {
				return item
			}
			
			var newItem = item
			
			newItem = ClassVariableRewriter(fromName: varName, className: className, file: currentFile).visit(item)
						
			return newItem
		})
													  
		return newBlockItemList
	}
}
