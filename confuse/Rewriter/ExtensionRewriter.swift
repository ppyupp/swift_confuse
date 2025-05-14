//
//  ExtensionRewriter.swift
//  confuse
//
//  Created by ppyupp on 2024/10/12.
//


import Foundation
import SwiftSyntax

public class ExtensionRewriter: BaseRewriter {
	var name = ""
	
	init(name: String) {
		self.name = name
	}
	
	// 修改类名, 方法名
	override public func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
		guard let name = node.extendedType.as(IdentifierTypeSyntax.self)?.name.text else{
			return super.visit(node)
		}
		
		
		if name != self.name {
			return super.visit(node)
		}
		
		var newNode = node
		
		var newName = kGlobal.buildName(name: name)
		
		var tt = node.extendedType.as(IdentifierTypeSyntax.self)
		
		tt!.name.tokenKind  = .identifier(newName)
		
		newNode.extendedType = TypeSyntax(tt!)
				
		var oldNames = [String]()
		
		var newMembers = newNode.memberBlock.members.compactMap { member -> MemberBlockItemListSyntax.Element? in
			
			if let function = member.decl.as(FunctionDeclSyntax.self) {
				// 不要修改override的方法
				if function.isOverride() {
					return member
				}
				
				let newFunc = self.modifyFunction(function)
								
				var newMember = member
				newMember.decl = DeclSyntax(newFunc)
								
				return newMember
			} else {
				return member
			}
		}
		
		newNode.memberBlock.members = MemberBlockItemListSyntax(newMembers)
		
		return super.visit(newNode)
	}
	
}
