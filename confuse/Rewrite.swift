
import Foundation
import SwiftSyntax

public class YYRewriter: SyntaxRewriter {
	override public func visit(_ token: TokenSyntax) -> TokenSyntax {
		switch token.tokenKind {
		case let .stringSegment(text):
			// print("result", text)
			var newToken = token
	
			// newToken.tokenKind = .stringSegment("fuck")
			
			return newToken
		case let .identifier(text):
			
			break
			
		// print("result2", text)
		default:
			return token
		}
		
		return token
	}
	
	override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
		return super.visit(node)
	}
	
	override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
		// print("class name", node.name.text)
		
		// print("class", node.memberBlock.members.first?.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text)
		
		var newNode = node
		
		// node.memberBlock.members.first?.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text = "s"
		
		// newNode.memberBlock.members = .init()
		
		// var vd = newNode.memberBlock.members.first?.decl.as(VariableDeclSyntax.self)
		
		// var dd = vd!.bindings.first!.pattern.as(IdentifierPatternSyntax.self)!
		
		// var id = IdentifierPatternSyntax()
		// dd.identifier = .stringSegment("vv")
		
		// print("ddd", dd.as(DeclSyntax.self))
		
		let newMembers = newNode.memberBlock.members.compactMap { member -> MemberBlockItemListSyntax.Element? in
			
			guard let variable = member.decl.as(VariableDeclSyntax.self) else { return member }
			
			/*
			 let n = member.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
			
			 if n == "sex"{
			 	//return nil
			 }
			  */
			
			let newBindings = variable.bindings.map { binding in
				
				guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
					return binding
				}
				
				var newBinding = binding
				var newIdent = ident
				
				print("class attribute", newIdent)
				
				if newIdent.identifier.text == "name" {
					newIdent.identifier.tokenKind = .identifier("nickname")
				}
								
				newBinding.pattern = PatternSyntax(newIdent)
				
				return newBinding
			}
			
			var newVariable = variable
			var newMember = member
			newVariable.bindings = PatternBindingListSyntax(newBindings)
			
			newMember.decl = DeclSyntax(newVariable)
			
			return newMember
		}
		
		newNode.memberBlock.members = MemberBlockItemListSyntax(newMembers)

		// newNode.memberBlock.members[newNode.memberBlock.members.index(at: 0)].decl =
		// newNode.memberBlock.members[0].decl = vd!.as(DeclSyntax.self)
		
		/*
		 newNode.memberBlock.members.map { m in
		 	//m.decl.as
		 }
		  */
		
		return super.visit(newNode)
	}
	
	
}
