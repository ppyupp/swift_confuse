//
//  ProjBuilder.swift
//  confuse
//
//  Created by ppyupp on 2024/10/11.
//

import Foundation
import PathKit
import XcodeProj

class ProjBuilder {
	var fromPath: String
	var toPath: String
	
	var proj: XcodeProj!
	
	var projectName = ""
	var projectRootPath: Path!
	var rootGroup: PBXGroup!
	var projectGroup: PBXGroup!
	
	var codeRootPath: Path!
	
	init(fromPath: String, toPath: String) {
		self.fromPath = fromPath
		self.toPath = toPath
		
		self.setup()
	}
	
	func rebuild() {
		self.clean()
		
		self.buildCodeTree(dirUrl: self.codeRootPath.url, group: self.projectGroup)
		
		do {
			try proj.write(path: Path(self.toPath), override: true)
			print("write Proj!")
		} catch {
			print(error)
		}
		
		
	}
	
	func setup() {
		guard var proj = try? XcodeProj(pathString: self.fromPath) else {
			print("ProjBuilder error: fromPath error", self.fromPath)
			exit(100)
		}
		
		self.proj = proj
		
		do {
			let rootProject = try self.proj.pbxproj.rootProject()
			self.projectName = rootProject?.name ?? ""
			
			self.rootGroup = self.proj.pbxproj.rootObject?.mainGroup
			
		} catch {
			print("ProjBuilder error: rootProject error", error)
			exit(100)
		}
		
		//print(self.projectName)
		
		let projectGroup = self.rootGroup.children.first { e in
			e.path == self.projectName
		}
		
		guard let pg = projectGroup as? PBXGroup else {
			print("ProjBuilder error: projectGroup not found")
			exit(100)
		}
		
		self.projectGroup = pg
		
		self.projectRootPath = Path(self.fromPath).parent().absolute()
		
		self.codeRootPath = try? pg.fullPath(sourceRoot: self.projectRootPath)
		
		// print(self.codeRootPath)
	}
	
	func buildCodeTree(dirUrl: URL, group: PBXGroup) {
		if let contents = try? FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil) {
			for u in contents {
				if u.lastPathComponent.first == "." {
					continue
				}
				
				let p = Path(u.path())
				
				if p.isDirectory {
					var grp: PBXGroup
					
					do {
						grp = try group.addGroup(named: u.lastPathComponent).first!
					} catch {
						print("ProjBuilder error: add group error", error)
						exit(100)
					}
					
					self.buildCodeTree(dirUrl: u, group: grp)
				} else {
					if u.pathExtension == "swift" {
						do {
							print("add file", self.projectRootPath)
							try group.addFile(at: Path(u.path()), sourceRoot: self.projectRootPath)
						} catch {
							print("ProjBuilder error: add file error,", error)
							exit(100)
						}
					}
				}
			}
		}
	}
	
	// 清理掉
	func clean() {
		// 移除所有swift文件的引用
		proj.pbxproj.fileReferences.forEach { f in
			guard let p = f.path else {
				return
			}
			
			let u = URL(filePath: p)
			if u.pathExtension == "swift" {
				proj.pbxproj.delete(object: f)
			}
		}
		
		// 移除空文件夹
		var ii = 0
		while true {
			var flag = false

			for g in proj.pbxproj.groups {
				if g.children.count == 0 {
					let p = g.parent as? PBXGroup
					proj.pbxproj.delete(object: g)
					flag = true
				}
			}

			ii += 1

			if !flag || ii > 1000 {
				break
			}
		}
	}
}
