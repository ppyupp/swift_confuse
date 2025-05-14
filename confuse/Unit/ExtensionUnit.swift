//
//  ExtensionUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/10/12.
//


import Foundation
import SwiftSyntax

class ExtensionUnit: NSObject {
	weak var file: FileUnit!

	var name: String
	var newName = ""

	var decl: ExtensionDeclSyntax?

	var funcList = [FuncUnit]()

	var newVarMap = [String: String]()

	// var type: String?

	init(name: String) {
		self.name = name
	}

	func setNewVarMap(newName: String, oldName: String) {
		self.newVarMap[newName] = oldName
	}

	func prepare() {

	}

	func findFunc(name: String) -> FuncUnit? {
		for v in self.funcList {
			if v.name == name {
				return v
			}
		}

		return nil
	}

	func findFunc(call: FunctionCallExprSyntax, exceptOverride: Bool = false) -> FuncUnit? {
		return findFunc(funcList: self.funcList, call: call, exceptOverride: exceptOverride)
	}

	func findFunc(funcList: [FuncUnit], call: FunctionCallExprSyntax, exceptOverride: Bool = false) -> FuncUnit? {
		var list = [FuncUnit]()
		for f in funcList {
			if exceptOverride && f.funcDecl!.isOverride() {
				continue
			}

			let r = f.isEq(call: call)
			if r {
				list.append(f)
			}
		}

		// 谁的参数短, 谁匹配
		list.sort { a, b in
			let an = a.funcDecl?.signature.parameterClause.parameters.count ?? 0
			let bn = b.funcDecl?.signature.parameterClause.parameters.count ?? 0
			return an < bn
		}

		return list.first
	}
}
