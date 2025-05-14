//
//  GLobal.swift
//  confuse
//
//  Created by ppyupp on 2024/7/14.
//

import Foundation
import SwiftSyntax

class Global {
	var fileList = [FileUnit]()
	
	var classList = [ClassUnit]()
	var extensionList = [ExtensionUnit]()
	
	var classMap = [String: ClassUnit]()

	var newClassMap = [String: String]()
	
	var maskClassList = [ClassDeclSyntax]()
	
	func prepare() {
		for c in self.classList {
			let classNameList = self.findClassList(name: c.name)
			
			c.classNameList = classNameList
			
			self.classMap[c.name] = c
		}
	}
	
	func buildName(name: String, type: String = "") -> String {
		return "benz_" + name
	}
	
	func setNewClass(newClassName: String, oldClassName: String) {
		self.newClassMap[newClassName] = oldClassName
	}
	
	func getRealClass(name: String?) -> String? {
		if name == nil {
			return nil
		}
		
		return self.findClass(name: name!)?.name
	}
	
	func getExtensionList(name: String) -> [ExtensionUnit] {
		var list = [ExtensionUnit]()
		
		for e in self.extensionList {
			if e.name == name {
				list.append(e)
			}
		}
		
		return list
	}

	func findClass(name: String) -> ClassUnit? {
		var className = name
		
		if self.newClassMap[name] != nil {
			className = self.newClassMap[name]!
		}
		
		// print("find class", name, className)
		
		for c in self.classList {
			if c.name == className {
				return c
			}
		}

		return nil
	}
	
	func findClassList(name: String) -> [String] {
		var list = [String]()
		
		var n = name
		while true {
			guard let c = self.findClass(name: n) else {
				break
			}
			
			list.append(c.name)
			
			if let p = c.classDecl?.inheritanceClause?.inheritedTypes.first?.type.as(IdentifierTypeSyntax.self)?.name.text {
				n = p
			} else {
				break
			}
		}
		
		return list
	}
	
	func findFuncParent(call: FunctionCallExprSyntax?) -> String? {
		guard let call = call else { return nil }
				
		return nil
	}
	
	func findParent(exprSyntax node: ExprSyntax?, currentFile: FileUnit) -> String? {
		guard let node = node else { return nil }
		
		if let decl = node.as(DeclReferenceExprSyntax.self) { // 直接就是一个变量
			return self.findParent(declReferenceExprSyntax: decl, currentFile: currentFile)
		}
		
		return nil
	}
	
	func findParent(declReferenceExprSyntax node: DeclReferenceExprSyntax, currentFile: FileUnit) -> String? {
		if let memberAccessExpr = node.parent?.as(MemberAccessExprSyntax.self) { // xxx.name的形式
			if memberAccessExpr.declName.id == node.id { // name
				dPrint("findParent, memberAccessExpr ....")
				dPrint(memberAccessExpr.description.trimmingCharacters(in: .whitespacesAndNewlines))
				
				if memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.Self) { // Self
					dPrint("findParent >> Self")
					
					if let c = self.findParentClassOrExtensionRealName(node: Syntax(node)) {
						return self.findVarClass(name: memberAccessExpr.declName.getName(), className: c)
					}
				} else if memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self) { // self
					dPrint("findParent >> self")
					if let c = self.findParentClassOrExtensionRealName(node: Syntax(node)) {
						return self.findVarClass(name: memberAccessExpr.declName.getName(), className: c)
					}
				} else if memberAccessExpr.base?.as(SuperExprSyntax.self) != nil { // super
					dPrint("findParent >> super")
					if let c = self.findClass(node: Syntax(node)) {
						if let p = c.getParentClass() {
							if let pc = self.findClass(name: p) {
								return self.findVarClass(name: memberAccessExpr.declName.getName(), className: pc.name)
							}
						}
					}
				} else if memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.kind == .token { // BaseViewController.name里面的BaseViewController
					dPrint("findParent >> xxx")
					
					let baseDecl = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)
					
					if let c = self.findVariable(node: baseDecl?.parent, name: baseDecl!.getName(), currentFile: currentFile) {
						dPrint("findParent >> xxx >>>", c)
						return c
					}
					
					return baseDecl?.getName()
				} else if let call = memberAccessExpr.base?.as(FunctionCallExprSyntax.self) { // xxx.xxx().name
					// 找到类型后, 在类(包括父类)里面查找var存在的class
					if let c = self.findType(functionCallExprSyntax: call, currentFile: currentFile) {
						return self.findVarClass(name: node.getName(), className: c)
					}
					
				} else if let opt = memberAccessExpr.base?.as(OptionalChainingExprSyntax.self) { // ?.name
					return self.findType(exprSyntax: ExprSyntax(opt), currentFile: currentFile) // TODO: 可能是opt.expression
				} else if let opt = memberAccessExpr.base?.as(ForceUnwrapExprSyntax.self) { // !.name
					// dDump(memberAccessExpr)
					// dPrint(self.findType(exprSyntax: ExprSyntax(opt.expression), currentFile: currentFile))
					// dPrint("is force unwrap =====")
					
					return self.findType(exprSyntax: ExprSyntax(opt.expression), currentFile: currentFile)
				} else { // 其他类型, 直接引用: name
					// dDump(memberAccessExpr)
					// dPrint(self.findType(exprSyntax: memberAccessExpr.base, currentFile: currentFile))
					// dPrint("=====")
					
					return self.findType(exprSyntax: memberAccessExpr.base, currentFile: currentFile)
				}
			} else {
				// dDump(node)
				// dPrint("===== single.pp ===")
				
				return self.findVarParent(declReferenceExprSyntax: node, currentFile: currentFile)
			}
		} else { // 直接使用的形式, 直接就: name
			return self.findVarParent(declReferenceExprSyntax: node, currentFile: currentFile)
		}
		
		return nil
	}
	
	// 查找变量的父 class
	func findVarParent(declReferenceExprSyntax node: DeclReferenceExprSyntax, currentFile: FileUnit) -> String? {
		// dDump(node)
		// dPrint("===== findVarParent ===")
		
		// 在scope里面找, 找到了, 证明是scope定义的, 没有parent
		// TODO: 可能应该用findLocalVariableTypeInCodeScope方法
		if let t = self.findLocalVariableTypeInCodeScope(node: Syntax(node), name: node.getName(), currentFile: currentFile) {
			// dPrint("in local scope...")
			
			return nil
		}
					
		dPrint("find parent class", self.findParentClassOrExtensionRealName(node: Syntax(node)))
		
		// class 的变量查找实例变量
		if let c = self.findParentClassOrExtensionRealName(node: Syntax(node)) {
			if let t = self.findVarClass(name: node.getName(), className: c) {
				dPrint("fund class", c, node.getName())
				
				// 找到了, 返回class, 而不是自己的类型
				return t
			}
		}
		
		return nil
	}
	
	func findType(declReferenceExprSyntax node: DeclReferenceExprSyntax, currentFile: FileUnit) -> String? {
		if let memberAccessExpr = node.parent?.as(MemberAccessExprSyntax.self) { // xxx.name的形式
			// xxx也是DeclReferenceExprSyntax
			// name也是DeclReferenceExprSyntax
			// 都会访问到
			
			if memberAccessExpr.declName.id == node.id { // name
				dPrint("findType(declReferenceExprSyntax is member access, name")
				dPrint(node)
				dPrint(memberAccessExpr.base)

				// dump(memberAccessExpr)
				
				// 父的type
				let ptype = self.findType(exprSyntax: memberAccessExpr.base, currentFile: currentFile)
				dPrint("parent", ptype)
				if let ptype = ptype {
					if let pc = self.findClass(name: ptype) {
						// print("parent2", pc.name, node.isFuncCall())
						
						if node.isFuncCall() {
							// 2024.7.15
							// 写到此处暂停
							// 需要先分析class的func(ClassVisitor, 未完成)
							dPrint("node.isFuncCall")
							if let f = pc.findFuncRecursive(call: node.parentFunctionCall!) {
								dPrint("get class, is func", f.getType())
								return f.getType()
							} else {
								if let f = self.searchFuncInMask(call: node.parentFunctionCall!) {
									dPrint("find in mask", f.getReturn())
									
									return f.getReturn()
								}
							}
						} else {
							let v = pc.findVar(name: node.getName())
							// print("get class, is var", v?.getType())
							return v?.getType()
						}
					}
				}
				
			} else if memberAccessExpr.base != nil, memberAccessExpr.base!.id == node.id { // xxx
				dPrint("xxxxpppp2", node.baseName.text)
				
				if node.baseName.text == "self" {
					// let n = self.findClassDecl(node: node.parent)?.name.text
					// 在class里
					if let n = self.findParentClassRealName(node: node.parent) {
						// print("xxxxpppp2 is self", n)
						return n
					}
					
					// 在extension里
					if let n = self.findParentExtensionName(node: node.parent) {
						// print("xxxxpppp2 is self", n)
						return n
					}
				} else if let n = self.findVariable(node: node.parent, name: node.getName(), currentFile: currentFile) {
					return n
				} else {
					return node.getName()
				}
			}
		} else { // 直接使用的形式
			if node.baseName.tokenKind == .keyword(.self) {
				// print("self....")
				if let c = self.findClassDecl(node: Syntax(node))?.name.text {
					return kGlobal.getRealClass(name: c)
				}
			} else {
				// print("ff0....")
				return self.findVariable(node: node.parent, name: node.getName(), currentFile: currentFile)
			}
		}
		
		return nil
	}
	
	func findType(exprSyntax node: ExprSyntax?, currentFile: FileUnit) -> String? {
		guard let node = node else { return nil }
		
		// print("findType(exprSyntax", node)
		
		if let decl = node.as(DeclReferenceExprSyntax.self) { // 直接就是一个变量
			dPrint("ssss....", decl)
			return self.findType(declReferenceExprSyntax: decl, currentFile: currentFile)
		} else if let opt = node.as(OptionalChainingExprSyntax.self) { // optional调用链, ?.xxx
			return self.findType(exprSyntax: opt.expression, currentFile: currentFile)
		} else if let f = node.as(FunctionCallExprSyntax.self) { // xxx().xxx的xxx()
			dPrint("find type, is func call ")
			return self.findType(functionCallExprSyntax: f, currentFile: currentFile)
		} else if let s = node.as(SuperExprSyntax.self) { // super.xxx的super
			return self.findType(superExprSyntax: s)
		} else if let s = node.as(MemberAccessExprSyntax.self) { // xxx.bbb的bbb
			dPrint("find type, is member access ")
			return self.findType(declReferenceExprSyntax: s.declName, currentFile: currentFile)
		}
		
		return nil
	}
	
	func findType(functionCallExprSyntax node: FunctionCallExprSyntax?, currentFile: FileUnit) -> String? {
		guard let node = node else { return nil }
		
		if let m = node.calledExpression.as(MemberAccessExprSyntax.self) {
			// 2024.7.14 晚上 22:23, 写到这里
			// 是成员方法
			// 如果base是self, 就在class里面找
			// 如果是变量, 就先找变量, 找到变量类型, 再找
			return self.findType(declReferenceExprSyntax: m.declName, currentFile: currentFile)
		} else if let d = node.calledExpression.as(DeclReferenceExprSyntax.self) {
			return self.findType(declReferenceExprSyntax: d, currentFile: currentFile)
		}
		
		return nil
	}
	
	func findType(superExprSyntax node: SuperExprSyntax?) -> String? {
		guard let node = node else {
			return nil
		}
				
		guard let currentClassName = self.findClassDecl(node: node.parent)?.name.text else {
			return nil
		}
		
		var className = currentClassName
		
		// print("sss", className)
		
		while true {
			guard let c = self.findClass(name: className) else {
				break
			}
			
			guard let c2 = c.getParentClass() else {
				break
			}
			
			guard let pClass = self.findClass(name: c2) else {
				break
			}
			
			className = c2
			
			if let call = node.parent?.parent?.as(FunctionCallExprSyntax.self) {
				if pClass.findFunc(call: call, exceptOverride: true) != nil {
					// print("find call", c2, call)
					return pClass.name
				}
			}
		}
		
		return nil
	}
	
	func findVariable(node: Syntax?, name: String, currentFile: FileUnit) -> String? {
		dPrint("base find", name)
		
		if let t = self.findLocalVariableTypeInCodeScope(node: node, name: name, currentFile: currentFile) {
			dPrint("in scope", t)
			return t
		}
		
		// 在func的方法定义里面找变量定义
		// 放到local方法了
		/*
		 if let funcDecl = self.findFuncDecl(node: node) {
		 	
		 dPrint("find in func args", funcDecl.findVar(name: name))
		 				
		 	if let t = funcDecl.findVar(name: name) {
		 		return t
		 	}
		 }
		  */
		
		// class 的变量查找实例变量
		if let c = self.findClass(node: node) {
			// let variableList = classDecl.getVariableList()
			for v in c.varList {
				// dPrint("vvv", v.name, name)
				if v.name == name {
					// dPrint("fund class", classDecl.name, name, v.getName())
					return self.findVariableType(variableDeclSyntax: v.varDecl!, currentFile: currentFile)
				}
			}
		}
		
		return nil
	}
	
	// 从node当前点, 往上找到name的定义, 找到就返回
	func findVariableTypeInCodeScope(node: Syntax?, name: String, currentFile: FileUnit) -> String? {
		// 先尝试在func里面查找本地变量
		// 层层往上找到变量定义列表, 对比名称, 获取类型
		
		var n: Syntax? = node
		while true {
			let block = self.findCodeBlock(node: n)
			
			if block == nil {
				break
			}
			
			// 在 code 里面找所有的变量定义语句
			let varList = self.findVariableDeclList(codeBockItemList: block?.statements)
			
			for v in varList {
				// 在这之后定义的变量, 忽略
				if v.position > node!.position {
					continue
				}
				
				if v.getName() == name {
					return self.findVariableType(variableDeclSyntax: v, currentFile: currentFile)
				}
			}
			
			// if 语句的变量定义 if let a = 1{}
			let bindingList = self.findOptionalBindingConditionList(codeBockItemList: block?.statements)
			// let bindingList2 = self.findOptionalBindingConditionList(currentFile: currentFile, codeBock: block)

			if bindingList.count > 0 {
				// print("bindingList", bindingList.count, bindingList2.count)
			}
						
			for v in bindingList {
				// 在这之后定义的变量, 忽略
				if v.position > node!.position {
					continue
				}
								
				if v.getName() == name {
					return self.findVariableType(optionalBindingConditionSyntax: v, currentFile: currentFile)
				}
			}
			
			// for 语句的变量定义 for ctx in xxx
			let forList = self.findForStmtList(codeBockItemList: block?.statements)
			
			if forList.count > 0 {
				// print("forList", forList.count)
			}
			
			for v in forList {
				// 在这之后定义的变量, 忽略
				if v.position > node!.position {
					continue
				}
								
				// if v.getVarName() == name {
				//	return self.findVariableType(forStmtSyntax: v, currentFile: currentFile)
				// }
			}
			
			// TODO: 上面的几种方式找到后, 要按照pos确认下优先级
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	// 从node当前点, 往上找到name的定义, 找到就返回
	func findLocalVariableTypeInCodeScope(node: Syntax?, name: String, currentFile: FileUnit) -> String? {
		// 先尝试在func里面查找本地变量
		// 层层往上找到变量定义列表, 对比名称, 获取类型
		
		var n: Syntax? = node
		while true {
			guard let p = n?.getPath() else {
				break
			}
			
			// 变量定义
			if let list = currentFile.getVariableDeclSyntaxList(scopePath: p) {
				for v in list {
					// 在这之后定义的变量, 忽略
					if v.position > node!.position {
						continue
					}
					
					if v.getName() == name {
						return kGlobal.findVariableType(variableDeclSyntax: v, currentFile: currentFile)
					}
				}
			}
			
			// if 语句的变量定义 if let a = 1{}
			if let list = currentFile.getOptionalBindingConditionSyntaxList(scopePath: p) {
				for v in list {
					// 在这之后定义的变量, 忽略
					if v.position > node!.position {
						continue
					}
					
					if v.getName() == name {
						return kGlobal.findVariableType(optionalBindingConditionSyntax: v, currentFile: currentFile)
					}
				}
			}
			
			// for 语句的变量定义 for ctx in xxx
			if let list = currentFile.getForStmtSyntaxList(scopePath: p) {
				for v in list {
					// 在这之后定义的变量, 忽略
					if v.position > node!.position {
						continue
					}
					
					let names = v.getVarNames()
					
					if let idx = names.firstIndex(of: name) {
						let forType = kGlobal.findVariableType(forStmtSyntax: v, index: idx, currentFile: currentFile)
						dPrint("in for==========>", names)
						dPrint("forType==========>", forType)
						
						
					}
					
					// if v.getVarName() == name {
					//
					// }
				}
			}
			
			// TODO: 上面的几种方式找到后, 要按照pos确认下优先级
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		if let closure = self.findClosureExpr(node: node) {
			dPrint("in closure")
			
			if closure.hasParameter(name: name) {
				dPrint("is closure param")
				
				if let t = self.searchClosureParameterType(closure: closure, name: name, currentFile: currentFile) {
					dPrint("closure type", t)
					return t
				}
			}
		}
		
		// 在func的方法定义里面找变量定义
		if let funcDecl = self.findFuncDecl(node: node) {
			dPrint("find in func args", funcDecl.findVar(name: name))
			
			if let t = funcDecl.findVar(name: name) {
				return t
			}
		}
		
		// 在init的方法定义里面找变量定义
		if let initDecl = self.findInitcDecl(node: node) {
			dPrint("find in init args", initDecl.findVar(name: name))
			
			if let t = initDecl.findVar(name: name) {
				return t
			}
		}
		
		return nil
	}

	func findRealClasstWithFunction(className: String, funcDecl: FunctionDeclSyntax) -> String? {
		guard let currentClass = self.findClass(name: className) else {
			return nil
		}
		
		// TODO: 是不是应该从后往前找, 直接找到继承类
		for name in currentClass.classNameList {
			guard let c = self.findClass(name: name) else {
				continue
			}
			
			for f in c.funcList {
				if f.funcDecl!.isOverride() {
					continue
				}
				
				if f.funcDecl!.isEq(funcDecl: funcDecl) {
					return c.name
				}
			}
		}
		
		return nil
	}
	
	func findRealClassWithFunction(className: String, call: FunctionCallExprSyntax) -> String? {
		guard let currentClass = self.findClass(name: className) else {
			return nil
		}
		
		// 从后往前找, 直接找到继承类, 避免子类的override func影响到
		for name in currentClass.classNameList.reversed() {
			guard let c = self.findClass(name: name) else {
				continue
			}
			
			if c.findFunc(call: call) != nil {
				return name
			}
		}
		
		return nil
	}
	
	func getSelfFunc(call: FunctionCallExprSyntax) -> FuncUnit? {
		// let classDecl = self.findClassDecl(node: call.parent)
		
		// if classDecl == nil {
		//	return nil
		// }
		
		// 在class里面
		var cu = self.findClass(node: call.parent)
		
		if cu == nil {
			// 在extension里面
			if let e = self.findParentExtensionRealName(node: call.parent) {
				cu = self.findClass(name: e)
			}
		}
		
		if cu == nil {
			return nil
		}
		
		let fn = cu?.findFuncRecursive(call: call)
		
		// print("aaa", cu?.name, fn)
		
		/*
		 let c = self.classList.filter { v in
		 	v.name == classDecl?.name.text
		 }.first
		
		 let fn = c?.findFunc(call: call)
		 */
		
		return fn
	}
	
	// func class
	func findClassDecl(node: Syntax?) -> ClassDeclSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(ClassDeclSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	// find func
	func findFuncDecl(node: Syntax?) -> FunctionDeclSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(FunctionDeclSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	// find Closure
	func findClosureExpr(node: Syntax?) -> ClosureExprSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(ClosureExprSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	// find init
	func findInitcDecl(node: Syntax?) -> InitializerDeclSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(InitializerDeclSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	// func extension
	func findParentExtensionName(node: Syntax?) -> String? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(ExtensionDeclSyntax.self) {
				return b.extendedType.as(IdentifierTypeSyntax.self)?.name.text
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	func findParentExtensionRealName(node: Syntax?) -> String? {
		guard let n = self.findParentExtensionName(node: node) else {
			return nil
		}
		
		if self.classMap[n] != nil {
			return n
		}
		
		if let n2 = self.newClassMap[n] {
			return n2
		}
		
		return nil
	}
	
	func findParentClassOrExtensionRealName(node: Syntax?) -> String? {
		if let c = self.findParentClassRealName(node: node) {
			return c
		}
		
		if let c = self.findParentExtensionRealName(node: node) {
			return c
		}
		
		return nil
	}
	
	func findParentClassRealName(node: Syntax?) -> String? {
		guard let n = self.findClassDecl(node: node)?.name.text else {
			return nil
		}
		
		if self.classMap[n] != nil {
			return n
		}
		
		if let n2 = self.newClassMap[n] {
			return n2
		}
		
		return nil
	}
	
	// func isClass
	func findClass(node: Syntax?) -> ClassUnit? {
		if let c = self.findClassDecl(node: node) {
			return self.findClass(name: c.name.text)
		}
		
		return nil
	}
	
	func findCodeBlock(node: Syntax?) -> CodeBlockSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(CodeBlockSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	func findCodeBlockItemList(node: Syntax?) -> CodeBlockItemListSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(CodeBlockItemListSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}
	
	func findCodeBlockItem(node: Syntax?) -> CodeBlockItemSyntax? {
		if node == nil {
			return nil
		}
		
		var n: Syntax? = node
		while true {
			if let b = n?.parent?.as(CodeBlockItemSyntax.self) {
				return b
			}
			
			n = n?.parent
			
			if n == nil {
				break
			}
		}
		
		return nil
	}

	// 变量定义语句
	func findVariableDeclList(codeBockItemList: CodeBlockItemListSyntax?) -> [VariableDeclSyntax] {
		var list = [VariableDeclSyntax]()
		codeBockItemList?.forEach { blockItem in
			if let v = blockItem.item.as(VariableDeclSyntax.self) {
				list.append(v)
			}
		}
		
		return list
	}
	
	// if条件的变量定义
	func findOptionalBindingConditionList(codeBockItemList: CodeBlockItemListSyntax?) -> [OptionalBindingConditionSyntax] {
		let findVisitor = FindVisitor()
		
		findVisitor.walk(codeBockItemList!.parent!)
		
		return findVisitor.optionalBindingConditionSyntaxList
	}
	
	func findOptionalBindingConditionList(currentFile: FileUnit, node: Syntax?) -> [OptionalBindingConditionSyntax] {
		let list = [OptionalBindingConditionSyntax]()
		
		if let path = node?.getPath() {
			if let t = currentFile.optionalBindingConditionSyntaxList[path] {
				return t
			}
		}
		
		return list
	}
	
	// for循环的变量定义
	func findForStmtList(codeBockItemList: CodeBlockItemListSyntax?) -> [ForStmtSyntax] {
		let findVisitor = FindVisitor()
		
		findVisitor.walk(codeBockItemList!.parent!)
		
		return findVisitor.forStmtSyntaxList
	}
	
	func findVariableType(variableDeclSyntax: VariableDeclSyntax, currentFile: FileUnit) -> String? {
		// dump(variableDeclSyntax)
		if let typeAnnotation = variableDeclSyntax.bindings.first?.typeAnnotation {
			if let n = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int
				return n
			} else if let n = typeAnnotation.type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int!
				return n
			} else if let n = typeAnnotation.type.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int?
				return n
			} else if let a = typeAnnotation.type.as(ArrayTypeSyntax.self) {
				// let a : []Int
				// 返回 Int
				return a.element.as(IdentifierTypeSyntax.self)?.name.text
			}
		}

		if let binding = variableDeclSyntax.bindings.first {
			// dump(binding)
			if let initializer = binding.initializer {
				if let f = initializer.value.as(FunctionCallExprSyntax.self) {
					// 方法调用或者类初始化
					
					if let c = self.findType(functionCallExprSyntax: f, currentFile: currentFile) {
						return c
					}
					
					return f.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
				} else if initializer.value.as(StringLiteralExprSyntax.self) != nil {
					return "String"
				} else if initializer.value.as(IntegerLiteralExprSyntax.self) != nil {
					return "Int"
				} else if initializer.value.as(DeclReferenceExprSyntax.self) != nil {
					if initializer.value.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self) {
						return self.findClassDecl(node: variableDeclSyntax.parent)?.name.text
					} else if initializer.value.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.Self) {
						return self.findClassDecl(node: variableDeclSyntax.parent)?.name.text
					}
				}
			}
		}

		return nil
	}
	
	func findVariableType(optionalBindingConditionSyntax: OptionalBindingConditionSyntax, currentFile: FileUnit) -> String? {
		// dump(variableDeclSyntax)
		
		if let value = optionalBindingConditionSyntax.initializer?.value {
			if let n = value.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int
				return n
			} else if let n = value.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int!
				return n
			} else if let n = value.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text {
				// let a : Int?
				return n
			} else if let f = value.as(FunctionCallExprSyntax.self) {
				if let c = self.findType(functionCallExprSyntax: f, currentFile: currentFile) {
					return c
				}
				
				// print("bid cakk", c3)
				
				return f.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
			}
		}
		
		return nil
	}
	
	func findVariableType(forStmtSyntax: ForStmtSyntax, index: Int, currentFile: FileUnit) -> String? {
		dPrint("for stmt var type", forStmtSyntax.getVarNames())
		
		let t = self.findType(exprSyntax: forStmtSyntax.sequence, currentFile: currentFile)
		
		dPrint("for stmt var type result", t)
		
		return t
	}
	
	// 在class里面找var, 包括父类 找到真正的类
	func findVarClass(name: String, className: String) -> String? {
		var c = self.findClass(name: className)
		
		while true {
			dPrint("ccc..fff..", c?.name, c?.findVar(name: name))
			
			if let v = c?.findVar(name: name) {
				return c?.name
			}
			
			guard let p = c?.getParentClass() else {
				break
			}
			
			c = self.findClass(name: p)
			
			if c == nil {
				break
			}
		}
		
		return nil
	}
	
	func searchClosureParameterType(closure: ClosureExprSyntax, name: String, currentFile: FileUnit) -> String? {
		var pos = closure.indexOfParameter(name: name)
		
		if pos < 0 {
			return nil
		}
		
		if let call = closure.parent?.as(FunctionCallExprSyntax.self) {
			// 闭包的parent是call
			dPrint("closure parent is call")
			
			// 闭包的定义
			var funcDecl: FunctionDeclSyntax?
			
			if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
				let parent = self.findType(exprSyntax: memberAccess.base, currentFile: currentFile)
				
				// 先在parent的方法里面找
				if let p = parent {
					if let pc = self.findClass(name: p) {
						if let f = pc.findFunc(call: call) {
							funcDecl = f.funcDecl
						}
					}
				}
				
				// 在mask里面找
				if funcDecl == nil {
					if let f = self.searchFuncInMask(call: call) {
						funcDecl = f
					}
				}
				
				if let funcDecl = funcDecl {
					dPrint("get func decl")
					
					if call.trailingClosure != nil, call.trailingClosure == closure {
						dPrint("is trailing closure")
											
						if let ff = funcDecl.signature.parameterClause.parameters.last?.type.as(FunctionTypeSyntax.self) {
							if let tt = ff.parameters[ff.parameters.index(at: pos)].type.as(IdentifierTypeSyntax.self)?.name.text {
								if tt == "Element" {
									return parent
								}
							}
						}
					}
				}
			}
			
		} else if let call = closure.parent?.as(LabeledExprSyntax.self) {
			// 函数的参数
		}
		
		return nil
	}
	
	func searchFunctionDecl(call: FunctionCallExprSyntax, currentFile: FileUnit) -> FunctionDeclSyntax? {
		if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
			// memberAccess.base
			
			let parent = self.findType(exprSyntax: memberAccess.base, currentFile: currentFile)
			
			dPrint("=>>>>", parent)
			
			if let p = parent {
				if let pc = self.findClass(name: p) {
					dPrint("find class unit", p)
					if let f = pc.findFunc(call: call) {
						return f.funcDecl
					}
				}
			}
			
			if let f = self.searchFuncInMask(call: call) {
				return f
			}
			
			// dDump(item: f)
			
		} else {}
		
		return nil
	}
	
	func searchFuncInMask(call: FunctionCallExprSyntax) -> FunctionDeclSyntax? {
		// dPrint("find in mask", self.maskClassList.count)
		
		for maskClass in self.maskClassList {
			if let ff = maskClass.findFunc(call: call) {
				// dPrint("find ok in mask!!!", call.getName())
				
				return ff
			}
		}
		
		return nil
	}
}
