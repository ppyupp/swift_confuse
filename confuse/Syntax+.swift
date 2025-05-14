//
//  category.swift
//  confuse
//
//  Created by ppyupp on 2024/7/11.
//

import Foundation
import SwiftSyntax

extension ForStmtSyntax {
	func getVarNames() -> [String] {
		var list = [String]()

		if let n = self.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
			list.append(n)
		} else if let t = self.pattern.as(TuplePatternSyntax.self) {
			t.elements.forEach { e in
				if let n = e.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
					list.append(n)
				}
			}
		}

		return list
	}
}

extension VariableDeclSyntax {
	var isStaticOrClass: Bool { modifiers.containsStaticOrClass }
	var isPublicOrOpen: Bool { modifiers.containsPublicOrOpen }
	var isOverride: Bool { modifiers.containsOverride }

	func getName() -> String? {
		if var binding = self.bindings.first {
			if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
				return identifierPattern.identifier.text.filter { !$0.isWhitespace }
			}
		}

		return nil
	}

	/*
	 func getType() -> String? {
	 	if let typeAnnotation = self.bindings.first?.typeAnnotation {
	 		if let n = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text {
	 			// let a : Int
	 			return n
	 		} else if let n = typeAnnotation.type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text {
	 			// let a : Int!
	 			return n
	 		}
	 	}

	 	// dump(self)

	 	if let binding = self.bindings.first {
	 		if let initializer = binding.initializer {
	 			if let f = initializer.value.as(FunctionCallExprSyntax.self) {
	 				// 方法调用或者类初始化
	 				// todo: 再次查找方法
	 				return f.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
	 			} else if initializer.value.as(StringLiteralExprSyntax.self) != nil {
	 				return "String"
	 			} else if initializer.value.as(IntegerLiteralExprSyntax.self) != nil {
	 				return "Int"
	 			} else if initializer.value.as(DeclReferenceExprSyntax.self) != nil {
	 				return initializer.value.as(DeclReferenceExprSyntax.self)?.baseName.text
	 			}
	 		}
	 	}

	 	return nil
	 }
	  */

	/*
	 var typeName: String {
	 	self.bindings.first?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text ?? ""
	 }
	  */
}

extension OptionalBindingConditionSyntax {
	func getName() -> String? {
		return self.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
		// return nil
	}
}

extension DeclReferenceExprSyntax {
	func getName() -> String {
		return self.baseName.text
	}

	func isFuncCall() -> Bool {
		return self.parentFunctionCall != nil
	}

	var parentFunctionCall: FunctionCallExprSyntax? {
		if let functionCall = self.parent?.as(FunctionCallExprSyntax.self) {
			// E.g `foo(a: 1)`
			return functionCall
		} else if let memberAccess = self.parent?.as(MemberAccessExprSyntax.self),
		          memberAccess.declName == self,
		          let functionCall = memberAccess.parent?.as(FunctionCallExprSyntax.self)
		{
			// E.g. `foo.bar(a: 1)``
			return functionCall
		} else {
			return nil
		}
	}
}

extension ClassDeclSyntax {
	func getVariableList() -> [VariableDeclSyntax] {
		var varList = [VariableDeclSyntax]()
		for member in self.memberBlock.members {
			if let v = member.decl.as(VariableDeclSyntax.self) {
				varList.append(v)
			}
		}

		return varList
	}

	func findFunctionWithName(_ name: String, isStaticOrClass: Bool,
	                          parameterCount: Int? = nil,
	                          numberOfParametersWithoutDefaults: Int? = nil)
		-> FunctionDeclSyntax?
	{
		for member: MemberBlockItemSyntax in memberBlock.members {
			guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
				continue
			}
			let hasStatic = funcDecl.modifiers.containsStaticOrClass
			guard hasStatic == isStaticOrClass else { continue }

			if let parameterCount {
				guard parameterCount == funcDecl.parameterCount else { continue }
			}
			if let numberOfParametersWithoutDefaults {
				guard numberOfParametersWithoutDefaults ==
					funcDecl.numberOfParametersWithoutDefaults else { continue }
			}

			// filter out operators and different names
			guard case .identifier(let idName) = funcDecl.name.tokenKind,
			      idName == name
			else {
				continue
			}

			// Found it
			return funcDecl
		}

		return nil
	}

	func findFunc(call: FunctionCallExprSyntax) -> FunctionDeclSyntax? {
		var funcList = [FunctionDeclSyntax]()

		for member in memberBlock.members {
			guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
				continue
			}

			funcList.append(funcDecl)
		}

		// dPrint("mama", funcList.count)

		// dDump(call)
		// dPrint("====")

		var list = [FunctionDeclSyntax]()
		for f in funcList {
			let r = f.isEq(call: call)
			if r {
				list.append(f)
			}

			// dDump(f)
			// dPrint("====")
		}

		// dPrint("=>>>><<<<", list.count)

		// 谁的参数短, 谁匹配
		list.sort { a, b in
			let an = a.signature.parameterClause.parameters.count ?? 0
			let bn = b.signature.parameterClause.parameters.count ?? 0
			return an < bn
		}

		return list.first
	}
}

extension InitializerDeclSyntax {
	var isConvenience: Bool {
		modifiers.contains { $0.name.tokenKind == .keyword(.convenience) }
	}

	var parameterCount: Int { signature.parameterClause.parameters.count }

	var numberOfParametersWithoutDefaults: Int {
		signature.parameterClause.parameters.numberOfParametersWithoutDefaults
	}

	func isOverride() -> Bool {
		for m in self.modifiers {
			if m.name.tokenKind == .keyword(.override) {
				return true
			}
		}

		return false
	}

	func findVar(name: String) -> String? {
		for v in signature.parameterClause.parameters {
			if v.secondName != nil, v.secondName?.text == name {
				return v.type.as(IdentifierTypeSyntax.self)?.name.text
			}

			if v.firstName.text == name {
				return v.type.as(IdentifierTypeSyntax.self)?.name.text
			}
		}

		return nil
	}

	func isEq(call: FunctionCallExprSyntax) -> Bool {
		let parameters = self.signature.parameterClause.parameters

		// 没有参数, 判为匹配
		if parameters.count == 0 && call.arguments.count == 0 {
			return true
		}

		if parameters.count == 0 && call.arguments.count > 0 {
			// 形参为空, 实参不为空, 判断为不匹配
			return false
		}

		if call.arguments.count == 0 {
			// 当实参为空, 形参全部带默认值, 判为匹配
			var n = 0
			for p in parameters {
				if p.defaultValue != nil {
					n += 1
				}
			}

			if n == parameters.count {
				return true
			}
		}

		// 用实参在形参里面找坑位
		// 找到一个坑位, 就把形参指针移动到下一位
		var index = 0
		for (i, a) in call.arguments.enumerated() {
			let r = self.findParam(from: index, arg: a)
			// print("fuck r", r)
			if r == -2 {
				return false
			}

			if r > -1 {
				index = r + 1
			}
		}

		// TODO: 需要加强尾随闭包的判断
		if index <= parameters.count - 1 {
			// 从index的下一个开始, 判断是否有默认值
			for y in index ..< parameters.count {
				let parm = parameters[parameters.index(at: y)]
				if parm.defaultValue == nil {
					if parm.isFuncType() { // 闭包
						if call.trailingClosure == nil {
							return false
						}
					} else {
						return false
					}
				}
			}
		}

		return true
	}

	func findParam(from: Int, arg: LabeledExprSyntax) -> Int {
		let parameters = self.signature.parameterClause.parameters

		for y in from ..< parameters.count {
			let param = parameters[parameters.index(at: y)]

			if arg.colon == nil {
				// 没有名字
				if param.firstName.tokenKind == .wildcard {
					return y
				} else {
					return -2
				}
			} else {
				// 有名字
				if param.firstName.tokenKind == .wildcard {
					if param.defaultValue != nil { // 有默认值, 下一个
						continue
					} else {
						return -2
					}
				} else {
					if param.firstName.text == arg.label?.text {
						return y
					} else {
						if param.defaultValue != nil { // 有默认值, 下体格
							continue
						} else {
							return -2
						}
					}
				}
			}
		}

		return -2
	}
}

extension FunctionParameterSyntax {
	// 是否是方法(闭包)
	func isFuncType() -> Bool {
		if let a = self.type.as(AttributedTypeSyntax.self) {
			if a.baseType.as(FunctionTypeSyntax.self) != nil {
				return true
			}
		}

		if let a = self.type.as(FunctionTypeSyntax.self) {
			return true
		}

		return false
	}

	func isEq(param: FunctionParameterSyntax) -> Bool {
		if self.type.as(IdentifierTypeSyntax.self)?.name.text == param.type.as(IdentifierTypeSyntax.self)?.name.text {
			if self.firstName.text == param.firstName.text {
				if self.secondName?.text == param.secondName?.text {
					return true
				}
			}
		}

		return false
	}
}

extension FunctionDeclSyntax {
	var parameterCount: Int { signature.parameterClause.parameters.count }

	var numberOfParametersWithoutDefaults: Int {
		signature.parameterClause.parameters.numberOfParametersWithoutDefaults
	}

	func findVar(name: String) -> String? {
		for v in signature.parameterClause.parameters {
			if v.secondName != nil, v.secondName?.text == name {
				return v.type.as(IdentifierTypeSyntax.self)?.name.text
			}

			if v.firstName.text == name {
				return v.type.as(IdentifierTypeSyntax.self)?.name.text
			}
		}

		return nil
	}

	var isInstance: Bool {
		for modifier in modifiers {
			for token in modifier.tokens(viewMode: .all) {
				if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
					return false
				}
			}
		}
		return true
	}

	func isOverride() -> Bool {
		for m in self.modifiers {
			if m.name.tokenKind == .keyword(.override) {
				return true
			}
		}

		return false
	}

	func isEq(funcDecl: FunctionDeclSyntax) -> Bool {
		// 名字不一样, 返回false
		if self.name.text != funcDecl.name.text {
			return false
		}

		// 参数数量不一样, 返回false
		if self.signature.parameterClause.parameters.count != funcDecl.signature.parameterClause.parameters.count {
			return false
		}

		// 返回值不同, 返回false
		if let a = self.signature.returnClause, let b = funcDecl.signature.returnClause {
			if !a.isEq(returnClause: b) {
				return false
			}
		}

		var num = 0
		for (i, v) in self.signature.parameterClause.parameters.enumerated() {
			let v2 = funcDecl.signature.parameterClause.parameters[funcDecl.signature.parameterClause.parameters.index(at: i)]

			if v.isEq(param: v2) {
				num += 1
			}
		}

		if num == self.signature.parameterClause.parameters.count {
			return true
		}

		return false
	}

	func isEq(call: FunctionCallExprSyntax) -> Bool {
		// print(self.name)

		let callName = call.getName()

		// dPrint("!!", callName, self.name.text)

		// 名字不同, 先排除
		if self.name.text != callName {
			return false
		}

		if self.name.text == "subscribe" {
			// dump(self.signature)
			// dump(call)
		}

		let parameters = self.signature.parameterClause.parameters

		// 没有参数, 判为匹配
		if parameters.count == 0 && call.arguments.count == 0 {
			return true
		}

		if parameters.count == 0 && call.arguments.count > 0 {
			// 形参为空, 实参不为空, 判断为不匹配
			return false
		}

		if call.arguments.count == 0 {
			// 当实参为空, 形参全部带默认值, 判为匹配
			var n = 0
			for p in parameters {
				if p.defaultValue != nil {
					n += 1
				}
			}

			if n == parameters.count {
				return true
			}
		}

		// 用实参在形参里面找坑位
		// 找到一个坑位, 就把形参指针移动到下一位
		var index = 0
		for (i, a) in call.arguments.enumerated() {
			let r = self.findParam(from: index, arg: a)
			// print("fuck r", r)
			if r == -2 {
				return false
			}

			if r > -1 {
				index = r + 1
			}
		}

		// dPrint("fuck index", index)

		// TODO: 需要加强尾随闭包的判断
		if index <= parameters.count - 1 {
			// 从index的下一个开始, 判断是否有默认值
			for y in index ..< parameters.count {
				// dPrint("eeeee")
				let param = parameters[parameters.index(at: y)]
				if param.defaultValue == nil {
					// dPrint("ggg", param.isFuncType())
					if param.isFuncType() { // 闭包
						if call.trailingClosure == nil {
							return false
						}
					} else {
						return false
					}
				}
			}
		}

		return true
	}

	func findParam(from: Int, arg: LabeledExprSyntax) -> Int {
		let parameters = self.signature.parameterClause.parameters

		for y in from ..< parameters.count {
			let param = parameters[parameters.index(at: y)]

			if arg.colon == nil {
				// 没有名字
				if param.firstName.tokenKind == .wildcard {
					return y
				} else {
					return -2
				}
			} else {
				// 有名字
				if param.firstName.tokenKind == .wildcard {
					if param.defaultValue != nil { // 有默认值, 下一个
						continue
					} else {
						return -2
					}
				} else {
					if param.firstName.text == arg.label?.text {
						return y
					} else {
						if param.defaultValue != nil { // 有默认值, 下体格
							continue
						} else {
							return -2
						}
					}
				}
			}
		}

		return -2
	}

	func findInCall(param: FunctionParameterSyntax, args: LabeledExprListSyntax, offset: Int = 0) -> Int {
		for y in offset ..< args.count {
			let arg = args[args.index(at: y)]

			if param.defaultValue != nil {
				// 如果有默认值, 找一个匹配的值
				// 找不到也不算匹配失败

				if param.firstName.tokenKind == .wildcard {
					// 没有名字
					// 暂时简单的找到一个没有名字的就算成功
					if arg.colon == nil {
						return y
					}
				} else {
					if arg.colon == nil {
						// 传参无名字, 没匹配上params, 等于没匹配
						return -2
					}
					// 有名字
					if arg.label?.text == param.firstName.text {
						return y
					}
				}
			} else {
				// 如果没有默认值
				// 找不到就算匹配失败
				if param.firstName.tokenKind == .wildcard {
					// 没有名字
					// 暂时简单的找到一个没有名字的就算成功
					if arg.colon == nil {
						return y
					}
				} else {
					// 有名字
					if arg.label?.text == param.firstName.text {
						return y
					}
				}
			}
		}

		// 如果有默认值, 找一个匹配的值
		// 找不到也不算匹配失败
		if param.defaultValue != nil {
			return -1
		}

		return -2
	}
	
	func getReturn() -> String?{
		if let t = self.signature.returnClause?.type.as(OptionalTypeSyntax.self){
			return t.wrappedType.description
		}
		
		return self.signature.returnClause.debugDescription
		
		return nil
	}
}

extension FunctionParameterListSyntax {
	var numberOfParametersWithoutDefaults: Int {
		var count = 0
		for parameter: FunctionParameterSyntax in self {
			guard parameter.defaultValue == nil else { continue }
			count += 1
		}
		return count
	}
}

extension DeclModifierListSyntax {
	var modifiers: Set<Keyword> {
		var modifiers = Set<Keyword>()
		for modifier in self {
			guard case .keyword(let keyword) = modifier.name.tokenKind else {
				continue
			}
			modifiers.insert(keyword)
		}
		return modifiers
	}

	func contains(_ keyword: Keyword) -> Bool {
		for modifier in self {
			guard case .keyword(let keywordMember) = modifier.name.tokenKind else {
				continue
			}
			if keyword == keywordMember { return true }
		}
		return false
	}

	var publicOrOpenModifier: Element? {
		self.first {
			switch $0.name.tokenKind {
			case .keyword(.public): return true
			case .keyword(.open): return true
			default: return false
			}
		}
	}

	var containsPublicOrOpen: Bool { publicOrOpenModifier != nil }

	var overrideModifier: Element? {
		self.first {
			switch $0.name.tokenKind {
			case .keyword(.override): return true
			default: return false
			}
		}
	}

	var containsOverride: Bool { overrideModifier != nil }

	var containsStaticOrClass: Bool {
		contains {
			switch $0.name.tokenKind {
			case .keyword(.static): return true
			case .keyword(.class): return true
			default: return false
			}
		}
	}
}

extension TypeSyntax {
	var identifier: String? {
		for token in tokens(viewMode: .all) {
			switch token.tokenKind {
			case .identifier(let identifier):
				return identifier
			default:
				break
			}
		}
		return nil
	}
}

extension OptionalTypeSyntax {
	func isEq(optionalType: OptionalTypeSyntax) -> Bool {
		if let a = self.wrappedType.as(IdentifierTypeSyntax.self), let b = optionalType.wrappedType.as(IdentifierTypeSyntax.self) {
			return a.name.text == b.name.text
		}

		return false
	}
}

extension ReturnClauseSyntax {
	func isEq(returnClause: ReturnClauseSyntax) -> Bool {
		if let a = self.type.as(OptionalTypeSyntax.self), let b = returnClause.type.as(OptionalTypeSyntax.self) {
			return a.isEq(optionalType: b)
		}

		if let a = self.type.as(IdentifierTypeSyntax.self), let b = returnClause.type.as(IdentifierTypeSyntax.self) {
			return a.name.text == b.name.text
		}

		return false
	}
}

extension ClosureExprSyntax {
	func hasParameter(name: String) -> Bool {
		return self.indexOfParameter(name: name) > -1
	}

	func indexOfParameter(name: String) -> Int {
		if self.signature?.parameterClause == nil {
			return -1
		}

		var pos = -1
		var i = 0
		self.signature?.parameterClause?.as(ClosureShorthandParameterListSyntax.self)?.forEach { p in
			if p.name.text == name {
				pos = i
				return
			}

			i += 1
		}

		return pos
	}
}

extension Syntax {
	func getPath() -> String? {
		let p = self.getPathList()

		if p.count > 0 {
			return p.joined(separator: "->")
		}

		return nil
	}

	func getPathList() -> [String] {
		var paths = [String]()

		var n = findScopeBlock(node: self)

		while true {
			if n == nil {
				break
			}

			if let s = n?.as(MemberBlockItemSyntax.self) {
				guard let itemList = s.parent?.as(MemberBlockItemListSyntax.self) else {
					break
				}

				var idx = 0
				for (k, v) in itemList.enumerated() {
					if v == s {
						idx = k
						paths.insert("MemberBlockItemList[\(idx)]", at: 0)
					}
				}

				if let t = findScopeBlock(node: Syntax(itemList)) {
					n = t
				} else {
					break
				}
			} else if let s = n?.as(CodeBlockItemSyntax.self) {
				guard let itemList = s.parent?.as(CodeBlockItemListSyntax.self) else {
					break
				}

				var idx = 0
				for (k, v) in itemList.enumerated() {
					if v == s {
						idx = k
						paths.insert("CodeBlockItemList[\(idx)]", at: 0)
					}
				}

				if let t = findScopeBlock(node: Syntax(itemList)) {
					n = t
				} else {
					break
				}
			}
		}

		return paths
	}
}

extension FunctionCallExprSyntax {
	func getName() -> String {
		var callName = ""

		if let d = self.calledExpression.as(DeclReferenceExprSyntax.self) {
			callName = d.getName()
		} else if let m = self.calledExpression.as(MemberAccessExprSyntax.self) {
			callName = m.declName.getName()
		}

		return callName
	}
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

func findMemberBlockItemList(node: Syntax?) -> MemberBlockItemListSyntax? {
	if node == nil {
		return nil
	}

	var n: Syntax? = node
	while true {
		if let b = n?.parent?.as(MemberBlockItemListSyntax.self) {
			return b
		}

		n = n?.parent

		if n == nil {
			break
		}
	}

	return nil
}

func findScopeBlock(node: Syntax?) -> Syntax? {
	if node == nil {
		return nil
	}

	var n: Syntax? = node
	while true {
		if let b = n?.parent?.as(MemberBlockItemSyntax.self) {
			return Syntax(b)
		}

		if let b = n?.parent?.as(CodeBlockItemSyntax.self) {
			return Syntax(b)
		}

		n = n?.parent

		if n == nil {
			break
		}
	}

	return nil
}
