
import Foundation

@objc protocol TestDelegate {
	@objc optional func ddd()
}

class Test: Test2, TestDelegate {
	var name1 = "123"
	var sex1 = 1

	func ABC() -> Int {
		return 0
	}

	func GetTest2() -> Test2 {
		return Test2()
	}
}

class Test3: Test {
	var name3 = "123"
	var sex3 = 1

	func CABC() -> Int {
		return 0
	}

	override func getNickname(_ a: Int = 0, _ b: String = "", _ c: Int = 3) -> String? {
		return nil
	}
}

class Test4 {
	var name3 = "123"
	var sex3 = 1

	func why() -> Int {
		let t = Test3()
		t.getNickname(3)

		return 0
	}
}

class Test2: NSObject {
	var tt: Test!
	var name = "123"

	func getNickname(_ a: Int = 0, _ b: Int = 0, d: Int = 2, c: Int) -> String? {
		let aa = self
		return aa.getTest()?.name
	}

	func getNickname(_ a: Int = 0, _ b: Int = 0, c: Int) -> String? {
		return getTest()?.name
	}

	func getNickname(a: Int = 0, _ b: String = "", _ c: Int = 3) -> String? {
		return self.getTest()?.name
	}

	func getNickname(_ a: Int = 0, _ b: String = "", _ c: Int = 3) -> String? {
		return self.getTest()?.name
	}

	func getTest() -> Test? {
		self.getNickname(a: 1)
		return Test()
	}
}
