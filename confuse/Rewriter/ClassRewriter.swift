
import Foundation
import SwiftSyntax

public class ClassRewriter: BaseRewriter {
	var className = ""
	
	init(className: String) {
		self.className = className
	}
	
	// 修改类名, 成员名, 方法名,  以及调用
	override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
		if node.name.text != self.className {
			return super.visit(node)
		}
		
		var newNode = node
		
		var newClassName = kGlobal.buildName(name: node.name.text)
		
		newNode.name.tokenKind = .identifier(newClassName)
		
		kGlobal.setNewClass(newClassName: newClassName, oldClassName: node.name.text)
		
		var oldNames = [String]()
		
		let classUnit = kGlobal.findClass(name: node.name.text)
				
		var newMembers = newNode.memberBlock.members.compactMap { member -> MemberBlockItemListSyntax.Element? in
			
			if let variable = member.decl.as(VariableDeclSyntax.self) {
				if variable.isOverride {
					return member
				}
				
				let newVariable = self.modifyVariable(variable)
				
				oldNames.append(variable.getName()!)
				
				var newMember = member
				newMember.decl = DeclSyntax(newVariable)
				
				classUnit?.setNewVarMap(newName: variable.getName()!, oldName: kGlobal.buildName(name: variable.getName()!))
				
				return newMember
			} else if let function = member.decl.as(FunctionDeclSyntax.self) {
				// 不要修改override的方法
				if function.isOverride() {
					return member
				}
				
				let newFunc = self.modifyFunction(function)
				
				var newMember = member
				newMember.decl = DeclSyntax(newFunc)
				
				return newMember
			} else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
				// 不要修改override的
				if initDecl.isOverride() {
					return member
				}
								
								
				let newInit = self.modifyInitializer(initDecl)
				
				var newMember = member
				newMember.decl = DeclSyntax(newInit)
				
				return newMember
			} else {
				return member
			}
		}
		
		newNode.memberBlock.members = MemberBlockItemListSyntax(newMembers)
		
		return super.visit(newNode)
	}
	
	func modifyVariable(_ variable: VariableDeclSyntax) -> VariableDeclSyntax {
		let newBindings = variable.bindings.map { binding in
			
			guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
				return binding
			}
			
			var newBinding = binding
			var newIdent = ident
										
			newIdent.identifier.tokenKind = .identifier(kGlobal.buildName(name: newIdent.identifier.text))
			
			newBinding.pattern = PatternSyntax(newIdent)
			
			return newBinding
		}
		
		var newVariable = variable
		
		newVariable.bindings = PatternBindingListSyntax(newBindings)
		
		return newVariable
	}
}
