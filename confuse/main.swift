//
//  main.swift
//  confuse
//
//  Created by ppyupp on 2024/7/11.
//

import Foundation
import PathKit
import SwiftParser
import SwiftSyntax
import XcodeProj

var kGlobal = Global()

run()

//runTestCode()

func run() {
	/*
	deleteFile("/Users/ppyupp/Desktop/cc5_out/cc5")

	do {
		try copyDir(from: "/Users/ppyupp/dev/ios/cc5/cc5/", to: "/Users/ppyupp/Desktop/cc5_out/cc5")
	} catch {
		print(error)
	}
	 */
	 

	let task = TaskRun(projectPath: "/Users/ppyupp/dev/ios/cc5/", outPath: "/Users/ppyupp/Desktop/", outName: "cc5_out")
	task.run()

	return ()

	/*
	 deleteFile("/Users/ppyupp/Desktop/tc/")

	 do {
	 	try copyDir(from: "/Users/ppyupp/dev/ios/test-confuse/", to: "/Users/ppyupp/Desktop/tc")
	 } catch {
	 	print(error)
	 }

	 try? copyFile(from: "/Users/ppyupp/dev/ios/wings/privilege/privilege/Libs.swift", to: "/Users/ppyupp/Desktop/tc/test-confuse/App/Libs.swift")

	 let projBuilder = ProjBuilder(fromPath: "/Users/ppyupp/Desktop/tc/test-confuse.xcodeproj", toPath: "/Users/ppyupp/Desktop/tc/test-confuse2.xcodeproj")
	 projBuilder.rebuild()
	 return ()
	  */

	run(projectPath: "/Users/ppyupp/dev/ios/test-confuse/test-confuse/")
	return ()
}

func run(projectPath _: String) {
	let projectPath = "/Users/ppyupp/dev/ios/test-confuse/test-confuse/"

	let ll = readDirAllFiles(dirUrl: URL(string: projectPath)!)

	var swiftFiles = [URL]()
	for u in ll {
		if u.pathExtension == "swift" {
			swiftFiles.append(u)
		}
	}

	processSwiftFileList(fileList: swiftFiles)

	/*
	 return ()

	 let list = readDir(dirPath: projectPath)

	 guard let list = list else { return }

	 for f in list {
	 	print(f, isFile(atPath: projectPath + f))
	 }

	 return ()
	  */
}

func processSwiftFileList(fileList: [URL]) {
	for u in fileList {
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

		let fVisitor = FileVisitor(file: fileUnit)
		fVisitor.walk(sourceSyntax)

		if fVisitor.classList.count > 0 {
			fileUnit.classList = fVisitor.classList
			kGlobal.classList += fVisitor.classList
		}

		fileUnit.ready()
	}

	for f in kGlobal.fileList {
		for c in f.classList {
			// print("class", c.name, f.filePath.lastPathComponent, c.hash)
			c.prepare()
		}
	}

	kGlobal.prepare()

	if let ff = kGlobal.fileList.first(where: { f in
		f.filePath.lastPathComponent == "ListViewController.swift"
	}) {
		// dump(ff.sourceSyntax)
	}

	var classAlter = ClassAlter(className: "BaseViewController")
	classAlter.run()

	// classAlter = ClassAlter(className: "ViewController")
	// classAlter.run()

	if let ff = kGlobal.fileList.first(where: { f in
		f.filePath.lastPathComponent == "BaseViewController.swift"
	}) {
		// print(ff.sourceSyntax.description)
	}

	// funcAlter = FuncAlter(className: "BaseViewController", funcName: "fuck2")
	// funcAlter.run()

	if let ff = kGlobal.fileList.first(where: { f in
		f.filePath.lastPathComponent == "ViewController.swift"
	}) {
		// print(ff.sourceSyntax.description)
	}

	if let ff = kGlobal.fileList.first(where: { f in
		f.filePath.lastPathComponent == "ListViewController.swift"
	}) {
		print(ff.sourceSyntax.description)
	}

	// print(kGlobal.findClass(name: "ViewController")?.classDecl)

	let out = "/Users/ppyupp/Desktop/confuse-out/"

	for f in kGlobal.fileList {
		writeFile(filePath: out + f.filePath.lastPathComponent, data: f.sourceSyntax.description.data(using: .utf8)!)
	}
}

func runTestCode() {
	let code = """
	for m in self.messageModelList.reversed() {
			 if m.type == .normal {
				 
			 }
		 }
	for var m in self.messageModelList.reversed() {
		   if m.type == .normal {
			   
		   }
	   }
	for (i, m) in self.messageModelList.reversed() {
		 if m.type == .normal {
			 
		 }
	 }

	"""

	let sourceSyntax = SwiftParser.Parser.parse(source: code)

	//let fv = FileVisitor(file: FileUnit(filePath: URL(string: "/")!, sourceSyntax: sourceSyntax))
	//fv.walk(sourceSyntax)

	dump(sourceSyntax)
}
