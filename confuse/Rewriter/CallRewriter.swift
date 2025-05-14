
import Foundation
import SwiftSyntax

public class CallRewriter: BaseRewriter {
	var className = ""
	var file: FileUnit
	
	init(className: String, file: FileUnit) {
		self.className = className
		self.file = file
	}
	
	// 改写继承class的 override方法
	override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
		var newNode = node
		
		// 查找override的方法
		if node.isOverride() {
			if let currentClassName = kGlobal.findClassDecl(node: node.parent)?.name.text {
				if let realClassName = kGlobal.findRealClasstWithFunction(className: currentClassName, funcDecl: node) {
					if realClassName == self.className {
						newNode = self.modifyFunction(node)
					}
				}
			}
		}
		
		return super.visit(newNode)
	}
	
	// 修改继承的相关的class
	override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
		var newNode = node
		
		let name = node.name.text
		if let types = node.inheritanceClause?.inheritedTypes {
			let newTypes = types.map { t in
				var newT = t
				if var ident = t.type.as(IdentifierTypeSyntax.self) {
					if ident.name.text == self.className {
						ident.name.tokenKind = .identifier(kGlobal.buildName(name: self.className))
						newT.type = TypeSyntax(ident)
					}
				}
				
				return newT
			}
			
			newNode.inheritanceClause?.inheritedTypes = InheritedTypeListSyntax(newTypes)
		}
		
		return super.visit(newNode)
	}
	
	// 修改func调用
	override public func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
		var newNode = node
		
		// let currentClassName = kGlobal.findParentClassRealName(node: node.parent) ?? ""
		// let currentExtName = kGlobal.findParentExtensionRealName(node: node.parent) ?? ""
				
		// if currentClassName != "RTCPhoneService" {
		// return super.visit(node)
		// }
		// if self.file.filePath.lastPathComponent == "RTCPhoneService.swift"{
		// print("=====", node.description.trimmingCharacters(in: .whitespacesAndNewlines))
		// }
		
		// if node.description.trimmingCharacters(in: .whitespacesAndNewlines) == "RTCMessageModel(time: pm.sendTime)" {
		//	kDebug = true
		//	print("modify func call", node.description.trimmingCharacters(in: .whitespacesAndNewlines), "line:", self.file.getLine(node: Syntax(node)))
		// print("modify var call type", kGlobal.findParent(declReferenceExprSyntax: token, currentFile: self.file))
		// }
					
		// 这里判断是否需要修改
		if let memberAccessExpr = node.calledExpression.as(MemberAccessExprSyntax.self) {
			let ptype = kGlobal.findType(exprSyntax: memberAccessExpr.base, currentFile: self.file)
			
			if kDebug {
				print("ccc", ptype, memberAccessExpr.base, memberAccessExpr.declName, self.className)
			}
				
			if let ptype = ptype {
				if ptype == self.className {
					// print("ok")
					newNode = self.modifyFunction(call: node)
				} else {
					// 找到方法所在的真实class(包括继承的方法)
					let realClassName = kGlobal.findRealClassWithFunction(className: ptype, call: node)
					if realClassName == self.className {
						newNode = self.modifyFunction(call: node)
					}
				}
			}
			
			// print("+++++")
				
		} else if let declReference = node.calledExpression.as(DeclReferenceExprSyntax.self) {
			if kDebug {
				// dump(node)
				print("+++++")
			}
			
			// if node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "print" {
			//	return super.visit(node)
			// }
			
			if kGlobal.getSelfFunc(call: node) != nil {
				newNode = self.modifyFunction(call: node)
				
				// dump(node)
				// print("+++++")
				
				if kDebug {
					print("...getSelfFunc")
				}
			
			} else {
				if declReference.baseName.text == self.className {
					if kDebug {
						print("is class init")
					}
					
					newNode = self.modifyClass(call: node)
				}
			}
		}
		
		kDebug = false
		
		return super.visit(newNode)
	}
	
	// 修改成员变量调用
	override public func visit(_ token: DeclReferenceExprSyntax) -> ExprSyntax {
		var newToken = token
		
		// 上级是func call, 就跳过
		if token.parentFunctionCall != nil {
			// lock.lock()
			return super.visit(token)
		}
		
		// let currentClassName = kGlobal.findParentClassRealName(node: token.parent) ?? ""
		// let currentExtName = kGlobal.findParentExtensionRealName(node: token.parent) ?? ""
		
		// print(currentExtName)
		// if currentExtName != "BaseVC" {
		//	return super.visit(token)
		// }
		
		// print("decl", token.getName())
		
		// if token.parent?.description.trimmingCharacters(in: .whitespacesAndNewlines) == "s == session" && token.description.trimmingCharacters(in: .whitespaces) == "session" {
		// if token.description.trimmingCharacters(in: .whitespacesAndNewlines) == "messageID" && kGlobal.findFuncDecl(node: token.parent)?.name.text == "end" {
		
		
		if token.parent?.description.trimmingCharacters(in: .whitespacesAndNewlines) == "v.message" &&
			token.description.trimmingCharacters(in: .whitespacesAndNewlines) == "message" && self.file.getLine(node: Syntax(token)) == 502 {
			kDebug = true
			print("modify var call", token.parent?.description.trimmingCharacters(in: .whitespacesAndNewlines), "line:", self.file.getLine(node: Syntax(token)))
			print(token.description)
			print("modify var call type", kGlobal.findParent(declReferenceExprSyntax: token, currentFile: self.file))
		}
		
		kDebug = false
				
		if let p = kGlobal.findParent(declReferenceExprSyntax: token, currentFile: self.file) {
			if p == self.className {
				newToken.baseName.tokenKind = .identifier(kGlobal.buildName(name: token.baseName.text))
			}
		} else if token.getName() == self.className {
			// class.xxx的掉用的class
			newToken.baseName.tokenKind = .identifier(kGlobal.buildName(name: token.baseName.text))
		}
		
		return super.visit(newToken)
	}
	
	// 修改类型定义
	override public func visit(_ node: TypeAnnotationSyntax) -> TypeAnnotationSyntax {
		var newNode = node
		
		if var ident = node.type.as(IdentifierTypeSyntax.self) {
			if ident.name.text == self.className {
				ident.name.tokenKind = .identifier(kGlobal.buildName(name: self.className))
				
				newNode.type = TypeSyntax(ident)
			}
		} else if var opt = node.type.as(OptionalTypeSyntax.self) {
			if var ident = opt.wrappedType.as(IdentifierTypeSyntax.self) {
				if ident.name.text == self.className {
					ident.name.tokenKind = .identifier(kGlobal.buildName(name: self.className))
					opt.wrappedType = TypeSyntax(ident)
					
					newNode.type = TypeSyntax(opt)
				}
			}
		}
		
		return super.visit(newNode)
	}
	
	override public func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
		var newNode = node
		
		if node.name.text == self.className {
			newNode.name.tokenKind = .identifier(kGlobal.buildName(name: self.className))
		}
		
		return super.visit(newNode)
	}
	
	// 调用实例方法的修改
	func modifyClass(call: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
		var newCall = call
		
		if let declReference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
			var newDecl = declReference
			newDecl.baseName.tokenKind = .identifier(kGlobal.buildName(name: declReference.baseName.text))
			newCall.calledExpression = ExprSyntax(newDecl)
		}
		
		// 如果是自定义的init方法, 就要修改参数名
		if let c = kGlobal.findClass(name: self.className) {
			for i in c.initList {
				if i.isEq(call: call) {
					if kDebug {
						print("is init method", i.initDecl?.signature.description)
					}
					
					newCall.arguments = LabeledExprListSyntax(call.arguments.map { t in
						var newT = t
						
						if t.label != nil {
							newT.label?.tokenKind = .identifier(kGlobal.buildName(name: t.label!.text))
						}
						
						return newT
					})
					
					break
				}
			}
		}
		
		return newCall
	}
	
	// 修改方法调用名字
	func modifyFunction(call: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
		var newCall = call
				
		guard let c = kGlobal.findClass(name: self.className) else {
			return call
		}
				
		if c.findFunc(call: call) == nil {
			return call
		}
				
		if let memberAccessExpr = call.calledExpression.as(MemberAccessExprSyntax.self) {
			var newMember = memberAccessExpr
			
			newMember.declName.baseName.tokenKind = .identifier(kGlobal.buildName(name: newMember.declName.baseName.text))
									
			newCall.calledExpression = ExprSyntax(newMember)
		} else if let declReference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
			var newDecl = declReference
			newDecl.baseName.tokenKind = .identifier(kGlobal.buildName(name: newDecl.baseName.text))
						
			newCall.calledExpression = ExprSyntax(newDecl)
		}
		
		newCall.arguments = LabeledExprListSyntax(call.arguments.map { t in
			var newT = t
			
			if t.label != nil {
				newT.label?.tokenKind = .identifier(kGlobal.buildName(name: t.label!.text))
			}
			
			return newT
		})
		
		return newCall
	}
	
	// 修改方法的定义名
	/*
	 func modifyFunction(_ funcDecl: FunctionDeclSyntax) -> FunctionDeclSyntax {
	 	var newFunc = funcDecl
	 	newFunc.name = .identifier(kGlobal.buildName(name: funcDecl.name.text))
		
	 	return newFunc
	 }
	  */
}
