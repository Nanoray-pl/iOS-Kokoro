// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Kokoro",
	platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
	products: [
		.library(name: "KokoroUtils", targets: ["KokoroUtils"]),
		.library(name: "KokoroUI", targets: ["KokoroUI"]),
		.library(name: "KokoroFetchable", targets: ["KokoroFetchable"]),
		.library(name: "KokoroHttp", targets: ["KokoroHttp"]),
		.library(name: "KokoroCoreData", targets: ["KokoroCoreData"]),
	],
	targets: [
		.target(
			name: "KokoroUtils",
			path: "KokoroUtils",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroUI",
			dependencies: ["KokoroUtils"],
			path: "KokoroUI",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroFetchable",
			dependencies: ["KokoroUtils"],
			path: "KokoroFetchable",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroHttp",
			dependencies: ["KokoroUtils"],
			path: "KokoroHttp",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroCoreData",
			path: "KokoroCoreData",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroResourceProvider",
			dependencies: ["KokoroUtils"],
			path: "KokoroResourceProvider",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroJobs",
			dependencies: ["KokoroUtils"],
			path: "KokoroJobs",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroCache",
			dependencies: ["KokoroUtils"],
			path: "KokoroCache",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroCacheResourceProvider",
			dependencies: ["KokoroUtils", "KokoroCache", "KokoroResourceProvider"],
			path: "KokoroCacheResourceProvider",
			exclude: ["Bootstrap/Info.plist"]
		),
//		.testTarget(
//			name: "KokoroCoreDataTests",
//			dependencies: ["KokoroCoreData"],
//			path: "KokoroCoreDataTests",
//			exclude: ["Bootstrap/Info.plist"],
//			resources: [.copy("Resources/TestModel.xcdatamodeld")]
//		)
	]
)
