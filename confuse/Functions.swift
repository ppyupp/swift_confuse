

import Foundation
import PathKit

@discardableResult
func writeFile(filePath: String, data: Data) -> Bool {
	if let url = URL(string: "file://" + filePath) {
		do {
			try data.write(to: url, options: .atomic)
			return true
		} catch {
			print(error)
		}
	}

	return false
}

func readFile(filePath: String?) -> Data? {
	guard let filePath = filePath else { return nil }
	if let url = URL(string: "file://" + filePath) {
		return try? Data(contentsOf: url)
	}

	return nil
}

func readDir(dirPath: String?) -> [String]? {
	guard let dirPath = dirPath else { return nil }

	if let contents = try? FileManager.default.contentsOfDirectory(atPath: dirPath) {
		return contents
	}

	return nil
}

func readDirAllFiles(dirUrl: URL) -> [URL] {
	var files = [URL]()

	if let contents = try? FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil) {
		for u in contents {
			if isDir(atPath: u.path()) {
				files += readDirAllFiles(dirUrl: u)
			} else {
				files.append(u)
			}
		}
	}

	return files
}

func copyDir(from: String, to: String) throws {
	let fileManager = FileManager.default

	// 确保目标路径不存在
	if fileManager.fileExists(atPath: to) {
		// try fileManager.removeItem(at: destinationURL)
		print("error, to path: ", to, " is exists")
		return ()
	}

	// 创建目标文件夹
	try fileManager.createDirectory(at: URL(filePath: to), withIntermediateDirectories: true, attributes: nil)

	// 获取源文件夹内容
	let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.nameKey]
	let fileURLs = try fileManager.contentsOfDirectory(at: URL(filePath: from), includingPropertiesForKeys: keys)

	// 复制每个文件或文件夹到目标路径
	for fileURL in fileURLs {
		let destinationSubURL = URL(filePath: to).appendingPathComponent(fileURL.lastPathComponent)
		if fileManager.fileExists(atPath: fileURL.path) {
			try fileManager.copyItem(at: fileURL, to: destinationSubURL)
		} else if fileManager.fileExists(atPath: URL(filePath: from).path) {
			try fileManager.copyItem(at: URL(filePath: from), to: destinationSubURL)
		}
	}
}

func copyFile(from: String, to: String) throws {
	let fileManager = FileManager.default

	// 确保目标路径不存在
	if fileManager.fileExists(atPath: to) {
		// try fileManager.removeItem(at: destinationURL)
		print("error, to path: ", to, " is exists")
		return ()
	}

	if fileManager.fileExists(atPath: from) {
		try fileManager.copyItem(at: URL(filePath: from), to: URL(filePath: to))
	} else {
		print("error, from path: ", to, " is not exists")
		return ()
	}
}

func deleteFile(_ path: String) {
	let fileManager = FileManager.default

	do {
		try fileManager.removeItem(atPath: path)
	} catch {
		print(error)
	}
}

func isFile(atPath: String) -> Bool {
	var isDir: ObjCBool = false
	let exists = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDir)

	return exists && !isDir.boolValue
}

func isDir(atPath: String) -> Bool {
	var isDir: ObjCBool = false
	let exists = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDir)

	return exists && isDir.boolValue
}

extension Collection {
	subscript(safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}

func dPrint(_ items: Any..., file: String = #file, line: Int = #line) {
	if !kDebug {
		return
	}
	
	let pp = Path(file)

	let output = items.map { String(describing: $0) }.joined(separator: " ")

	// 打印带有时间戳和来源信息的输出
	print(output, " [\(pp.lastComponent):\(line)]")
}

func dDump(item: Any) {
	if kDebug {
		dump(item)
	}
}
