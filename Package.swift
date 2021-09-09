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
		.library(name: "KokoroResourceProvider", targets: ["KokoroResourceProvider"]),
		.library(name: "KokoroJobs", targets: ["KokoroJobs"]),
		.library(name: "KokoroCache", targets: ["KokoroCache"]),
		.library(name: "KokoroValueStore", targets: ["KokoroValueStore"]),
		.library(name: "KokoroCacheResourceProvider", targets: ["KokoroCacheResourceProvider"]),
		.library(name: "KokoroUIResourceProvider", targets: ["KokoroUIResourceProvider"]),
		.library(name: "KokoroCoreDataFetchable", targets: ["KokoroCoreDataFetchable"]),
		.library(name: "KokoroDI", targets: ["KokoroDI"]),
	],
	targets: [
		.target(
			name: "KokoroUtils",
			path: "KokoroUtils",
			exclude: ["Bootstrap/Info.plist"]
		),
		.testTarget(
			name: "KokoroUtilsTests",
			dependencies: ["KokoroUtils"],
			path: "KokoroUtilsTests",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroUI",
			dependencies: ["KokoroUtils"],
			path: "KokoroUI",
			exclude: ["Bootstrap/Info.plist"],
			swiftSettings: [
				.define("DEBUG", .when(configuration: .debug))
			]
		),
		.target(
			name: "KokoroFetchable",
			dependencies: ["KokoroUtils"],
			path: "KokoroFetchable",
			exclude: ["Bootstrap/Info.plist"]
		),
		.testTarget(
			name: "KokoroFetchableTests",
			dependencies: ["KokoroFetchable"],
			path: "KokoroFetchableTests",
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
			dependencies: ["KokoroUtils"],
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
		.testTarget(
			name: "KokoroCacheTests",
			dependencies: ["KokoroCache"],
			path: "KokoroCacheTests",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroValueStore",
			dependencies: ["KokoroUtils"],
			path: "KokoroValueStore",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroCacheResourceProvider",
			dependencies: ["KokoroUtils", "KokoroCache", "KokoroResourceProvider"],
			path: "KokoroCacheResourceProvider",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroUIResourceProvider",
			dependencies: ["KokoroUtils", "KokoroUI", "KokoroResourceProvider"],
			path: "KokoroUIResourceProvider",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroCoreDataFetchable",
			dependencies: ["KokoroUtils", "KokoroCoreData", "KokoroFetchable"],
			path: "KokoroCoreDataFetchable",
			exclude: ["Bootstrap/Info.plist"]
		),
		.target(
			name: "KokoroDI",
			dependencies: ["KokoroUtils"],
			path: "KokoroDI",
			exclude: ["Bootstrap/Info.plist"]
		),
		.testTarget(
			name: "KokoroDITests",
			dependencies: ["KokoroDI"],
			path: "KokoroDITests",
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
