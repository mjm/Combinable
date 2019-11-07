import XCTest

import CombinableTests

var tests = [XCTestCaseEntry]()
tests += CombinableTests.allTests()
XCTMain(tests)
