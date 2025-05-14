//
//  TaskRun.swift
//  confuse
//
//  Created by ppyupp on 2024/10/12.
//

import Foundation
import PathKit
import SwiftParser
import SwiftSyntax

let TestFiles = [ /* "RTCService.swift", "BaseVC.swift", "RTCPhoneSession.swift", "RTCPhoneService.swift", "RTCPhoneVC.swift", */ "RTCBaseChatSession.swift", "RTCMessageModel.swift" /* "AngleViewController.swift", "ViewController.swift" */ ]

var kDebug = false
var kTest = true

class TaskRun {
	var projBuilder: ProjBuilder!

	var fromProjectPath: Path!

	var outProjectXcodeProjPath: Path!

	var outPath: Path!
	var outName: String!
	var fullOutPath: Path!

	var swiftFiles = [URL]()

	init(projectPath: String!, outPath: String, outName: String) {
		self.fromProjectPath = Path(projectPath)
		self.outPath = Path(outPath)
		self.outName = outName

		if !self.fromProjectPath.exists {
			print(self.fromProjectPath, "not exists")
			exit(100)
		}

		if !self.outPath.exists {
			print(self.outPath, "not exists")
			exit(100)
		}

		// print()

		self.fullOutPath = self.outPath + Path(self.outName)

		/*
		 if self.fullOutPath.exists {
		 	print(self.fullOutPath, "is exists")
		 	exit(100)
		 }
		  */

		do {
			let children = try self.fullOutPath.children()
			for c in children {
				if c.extension == "xcodeproj" {
					self.outProjectXcodeProjPath = c
				}
			}
		} catch {
			print(error)
		}

		if self.outProjectXcodeProjPath == nil {
			print("xcodeproj not found")
			exit(100)
		}

		self.projBuilder = ProjBuilder(fromPath: self.outProjectXcodeProjPath.absolute().string, toPath: (self.fullOutPath + Path("o.xcodeproj")).absolute().string)

		// print(self.projBuilder.codeRootPath)
	}

	func initMask() {
		let maskFile = "/Users/ppyupp/dev/ios/confuse/confuse/Mask.swift"

		guard let sourceData = readFile(filePath: maskFile) else {
			print("Mask File at path isn't readable: \(maskFile)")
			return
		}

		guard let source = String(data: sourceData, encoding: .utf8) else {
			print("Mask File to string error: \(maskFile)")
			return
		}

		let sourceSyntax = SwiftParser.Parser.parse(source: source)

		let declVisitor = DeclVisitor()
		declVisitor.walk(sourceSyntax)
		
		kGlobal.maskClassList = declVisitor.classDeclList
	}

	func run() {
		
		self.initMask()
		
		/*
		 do {
		 	try copyDir(from: self.projectPath.absolute().string, to: self.fullOutPath.absolute().string)
		 } catch {
		 	print(error)
		 }
		  */

		let ll = readDirAllFiles(dirUrl: self.projBuilder.codeRootPath.url)

		for u in ll {
			if u.pathExtension == "swift" {
				swiftFiles.append(u)
			}
		}

		// print(swiftFiles)

		self.processSwiftFileList()
	}

	func processSwiftFileList() {
		for u in self.swiftFiles {
			let fileName = u.lastPathComponent

			if !TestFiles.contains(fileName) {
				if kTest {
					continue
				}
			}

			let path = Path(u.absoluteString)

			if path.match("*/PB/*.swift") {
				continue
			}

			print("processing", u.lastPathComponent)

			guard let sourceData = readFile(filePath: u.absoluteString) else {
				print("File at path isn't readable: \(u.absoluteString)")
				return
			}

			guard let source = String(data: sourceData, encoding: .utf8) else {
				print("File to string error: \(u.absoluteString)")
				return
			}

			let sourceSyntax = SwiftParser.Parser.parse(source: source)

			let fileUnit = FileUnit(filePath: u, sourceSyntax: sourceSyntax)

			kGlobal.fileList.append(fileUnit)

			let fileVisitor = FileVisitor(file: fileUnit)
			fileVisitor.walk(sourceSyntax)

			fileUnit.variableDeclSyntaxList = fileVisitor.variableDeclSyntaxList
			fileUnit.optionalBindingConditionSyntaxList = fileVisitor.optionalBindingConditionSyntaxList
			fileUnit.forStmtSyntaxList = fileVisitor.forStmtSyntaxList

			// print(fileUnit.optionalBindingConditionSyntaxList.keys)

			if fileVisitor.classList.count > 0 {
				fileUnit.classList = fileVisitor.classList

				kGlobal.classList += fileVisitor.classList
			}

			if fileVisitor.extensionList.count > 0 {
				fileUnit.extensionList = fileVisitor.extensionList

				kGlobal.extensionList += fileVisitor.extensionList
			}

			fileUnit.ready()
		}

		// print("extendsion", kGlobal.extensionList.count)

		for f in kGlobal.fileList {
			for c in f.classList {
				// print("class", c.name, f.filePath.lastPathComponent, c.hash)
				c.prepare()
			}
		}

		if let ff = kGlobal.fileList.first(where: { f in
			f.filePath.lastPathComponent == "RTCPhoneVC.swift"
		}) {
			// dump(ff.sourceSyntax)
		}

		kGlobal.prepare()

		if !kTest {
			self.runAlter(className: "BaseVC")
			self.runAlter(className: "RTCService")
			self.runAlter(className: "RTCPhoneSession")
			self.runAlter(className: "RTCPhoneService")
		}

		self.runAlter(className: "RTCMessageModel")

		if let ff = kGlobal.fileList.first(where: { f in
			f.filePath.lastPathComponent == "RTCBaseChatSession.swift"
		}) {
			//print(ff.sourceSyntax.description)
		}

		for f in kGlobal.fileList {
			if !kTest {
				writeFile(filePath: f.filePath.absoluteString, data: f.sourceSyntax.description.data(using: .utf8)!)
			}
		}

		print("success!")

		/*
		 for f in kGlobal.fileList {
		 	print("====", f.filePath.lastPathComponent)

		 	let fileVisitor = FileVisitor(file: f)
		 	fileVisitor.walk(f.sourceSyntax)

		 	print(f.sourceSyntax.description)
		 }
		  */
	}

	func runAlter(className: String) {
		guard let c = kGlobal.findClass(name: className) else {
			print("Alter error, class not found: ", className)
			return
		}

		var classAlter = ClassAlter(className: className)
		classAlter.run()
	}
}
