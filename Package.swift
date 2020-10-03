// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Kokoro",
	platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
	products: [
		.library(name: "KokoroUtils", targets: ["KokoroUtils"])
	],
	dependencies: [],
	targets: [
		.target(name: "KokoroUtils", path: "KokoroUtils")
//		.testTarget(name: "KokoroUtilsTests", dependencies: ["KokoroUtils"], path: "KokoroUtilsTests")
	]
)
