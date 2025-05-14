//
//  ClassUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/9/3.
//

import Foundation
import SwiftSyntax

class ClassUnit: NSObject {
	weak var file: FileUnit!

	var name: String
	var newName = ""

	var classNameList = [String]() // 自己的和继承的

	var classDecl: ClassDeclSyntax?

	var varList = [VarUnit]()
	var initList = [InitUnit]()
	var funcList = [FuncUnit]()

	var newVarMap = [String: String]()

	// var type: String?

	init(name: String) {
		self.name = name
	}

	func setNewVarMap(newName: String, oldName: String) {
		self.newVarMap[newName] = oldName
	}

	func getParentClass() -> String? {
		if self.classNameList.count == 1 {
			return nil
		}

		guard let n = self.classNameList[safe: 1] else {
			return nil
		}

		if kGlobal.findClass(name: n) != nil {
			return n
		}

		return nil
	}

	func prepare() {
		let classNameList = kGlobal.findClassList(name: self.name)

		self.classNameList = classNameList

		// print("prepare", self.classNameList)
		
		//for f in self.funcList{
			//print(f.getType())
		//}
		
		for v in self.varList{
			v.file = self.file
		}
	}

	func findVar(name: String) -> VarUnit? {
		for v in self.varList {
			if v.name == name {
				return v
			}
		}

		return nil
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

	// 包括父类的方法查找
	func findFuncRecursive(call: FunctionCallExprSyntax, exceptOverride: Bool = false) -> FuncUnit? {
		var list = self.funcList

		var c = self
		while true {
			//if list.count == 0 {
			//	break
			//}

			if let f = self.findFunc(funcList: c.funcList, call: call, exceptOverride: exceptOverride) {
				return f
			}

			guard let p = c.getParentClass() else {
				break
			}
			
			//print("ccc", c.name, p)

			guard let _c = kGlobal.findClass(name: p) else {
				break
			}

			c = _c
		}

		return nil
	}

	func findFunc(funcList: [FuncUnit], call: FunctionCallExprSyntax, exceptOverride: Bool = false) -> FuncUnit? {
		
		//print("find func")
		for f in self.funcList {
			//print("nn", f.name)
		}
		
		var list = [FuncUnit]()
		for f in self.funcList {
			if exceptOverride && f.funcDecl!.isOverride() {
				continue
			}

			let r = f.isEq(call: call)
			if r {
				list.append(f)
			}
		}
		
		//print("find func r", list.count, call)
		
		let extList = kGlobal.getExtensionList(name: self.name)
		
		for e in extList{
			for f in e.funcList {
				if exceptOverride && f.funcDecl!.isOverride() {
					continue
				}

				let r = f.isEq(call: call)
				if r {
					list.append(f)
				}
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
