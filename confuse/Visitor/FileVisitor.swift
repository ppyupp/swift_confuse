//
//  FileVisitor.swift
//  confuse
//
//  Created by ppyupp on 2024/7/14.
//

import Foundation
import SwiftSyntax

public class FileVisitor: BaseVisitor {
	var classList = [ClassUnit]()
	var extensionList = [ExtensionUnit]()
		
	var variableDeclSyntaxList = [String: [VariableDeclSyntax]]() // 变量定义
	var optionalBindingConditionSyntaxList = [String: [OptionalBindingConditionSyntax]]() // if里的变量定义
	var forStmtSyntaxList = [String: [ForStmtSyntax]]() // for里的变量定义
	
	var file: FileUnit
	var locationConverter: SourceLocationConverter
	
	init(file: FileUnit) {
		self.file = file
		self.locationConverter = SourceLocationConverter(fileName: "", tree: self.file.sourceSyntax)
	}

	override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		let classUnit = ClassUnit(name: node.name.text)
		
		classUnit.classDecl = node
		
		// class变量
		var varList = [VariableDeclSyntax]()
		for member in node.memberBlock.members {
			if let v = member.decl.as(VariableDeclSyntax.self) {
				varList.append(v)
			}
		}
		
		for v in varList {
			let varUnit = VarUnit(name: v.getName() ?? "", parentClass: classUnit)
			varUnit.varDecl = v
			
			classUnit.varList.append(varUnit)
		}
		
		// class的方法定义
		var funcList = [FunctionDeclSyntax]()
		for member in node.memberBlock.members {
			if let v = member.decl.as(FunctionDeclSyntax.self) {
				funcList.append(v)
			}
		}
		
		for v in funcList {
			let funcUnit = FuncUnit(name: v.name.text, parentClass: classUnit)
			funcUnit.funcDecl = v
			funcUnit.className = classUnit.name
			
			classUnit.funcList.append(funcUnit)
		}
		
		
		// class的init
		var initList = [InitializerDeclSyntax]()
		for member in node.memberBlock.members {
			if let v = member.decl.as(InitializerDeclSyntax.self) {
				initList.append(v)
			}
		}
		
		for v in initList {
			let initUnit = InitUnit(parentClass: classUnit)
			initUnit.initDecl = v
			initUnit.className = classUnit.name
			
			classUnit.initList.append(initUnit)
		}
		
		
		/////////////////
		
		self.classList.append(classUnit)
		
		return .visitChildren
	}
	
	override public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		let name = node.extendedType.as(IdentifierTypeSyntax.self)?.name.text
		
		let extensionUnit = ExtensionUnit(name: name!)
		
		extensionUnit.decl = node
		
		// extension的方法定义
		var funcList = [FunctionDeclSyntax]()
		for member in node.memberBlock.members {
			if let v = member.decl.as(FunctionDeclSyntax.self) {
				funcList.append(v)
			}
		}
		
		for v in funcList {
			let funcUnit = FuncUnit(name: v.name.text, parentExtension: extensionUnit)
			funcUnit.funcDecl = v
			funcUnit.className = extensionUnit.name
			
			extensionUnit.funcList.append(funcUnit)
		}
		
		self.extensionList.append(extensionUnit)
		
		return .visitChildren
	}
	
	override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		
		// 排除类定义的成员, 只需要局部变量
		if node.parent?.as(MemberBlockItemSyntax.self) != nil {
			//print("......", node)
			return .visitChildren
		}
		
		if let p = Syntax(node.parent!).getPath() {
			//print(p, node.description.trimmingCharacters(in: .whitespaces))
			var list = [VariableDeclSyntax]()
						
			if let t = self.variableDeclSyntaxList[p] {
				list = t
			}
			
			list.append(node)
			
			self.variableDeclSyntaxList[p] = list
		}
		
		return .visitChildren
	}
	
	override public func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
		if let p = Syntax(node).getPath() {
			//print(p, node.description.trimmingCharacters(in: .whitespaces))
			var list = [OptionalBindingConditionSyntax]()
						
			if let t = self.optionalBindingConditionSyntaxList[p] {
				list = t
			}
			
			list.append(node)
			
			self.optionalBindingConditionSyntaxList[p] = list
		}
		
		return .visitChildren
	}

	override public func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
		if let p = Syntax(node).getPath() {
			var list = [ForStmtSyntax]()
						
			if let t = self.forStmtSyntaxList[p] {
				list = t
			}
			
			list.append(node)
			
			self.forStmtSyntaxList[p] = list
		}
		
		return .visitChildren
	}
	
	override public func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
		return .visitChildren
	}
}
