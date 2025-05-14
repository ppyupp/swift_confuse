//
//  FuncUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/9/3.
//

import Foundation
import SwiftSyntax

class FuncUnit {
	weak var file: FileUnit!

	var name: String
	var className: String?

	weak var parentClass: ClassUnit?
	weak var parentExtension: ExtensionUnit?

	var funcDecl: FunctionDeclSyntax?

	init(name: String, parentClass: ClassUnit? = nil, parentExtension: ExtensionUnit? = nil) {
		self.name = name
		self.parentClass = parentClass
		self.parentExtension = parentExtension
	}

	func isEq(call: FunctionCallExprSyntax) -> Bool {
		guard let funcDecl = self.funcDecl else {
			return false
		}

		return funcDecl.isEq(call: call)
	}

	func getType() -> String? {
		if self.funcDecl?.signature.returnClause == nil {
			return nil
		}

		//dump(self.funcDecl?.signature)

		if let ident = self.funcDecl?.signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
			return ident.name.text
		} else if let ident = self.funcDecl?.signature.returnClause?.type.as(OptionalTypeSyntax.self) {
			return ident.wrappedType.as(IdentifierTypeSyntax.self)?.name.text
		}

		return nil
	}
}
