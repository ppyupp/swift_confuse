//
//  InitUnit.swift
//  confuse
//
//  Created by ppyupp on 2024/10/26.
//

import Foundation
import SwiftSyntax

class InitUnit {
	weak var file: FileUnit!

	var className: String?

	weak var parentClass: ClassUnit?
	weak var parentExtension: ExtensionUnit?

	var initDecl: InitializerDeclSyntax?

	init(parentClass: ClassUnit? = nil, parentExtension: ExtensionUnit? = nil) {
		// self.name = name
		self.parentClass = parentClass
		self.parentExtension = parentExtension
	}

	func isEq(call: FunctionCallExprSyntax) -> Bool {
		guard let initDecl = self.initDecl else {
			return false
		}

		if call.getName() != self.className {
			return false
		}

		return initDecl.isEq(call: call)
	}
}
