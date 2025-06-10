//swift-tools-version:5.9

import PackageDescription

extension Target {
  static func astrolabe() -> Target {
    #if os(tvOS)
      return .target(name: "Astrolabe", 
                     dependencies: [
                       .product(name: "RxSwift", package: "RxSwift"),
                       .product(name: "RxCocoa", package: "RxSwift")
                     ],
                     path: "./Sources/Core",
                     exclude: [
                      "./Sources/Core/CollectionViewReusedPagerSource.swift",
                      "./Sources/Core/CollectionViewPagerSource.swift",                      
                      "./Sources/Core/ReusedPagerCollectionViewCell.swift",
                      "./Sources/Core/PagerCollectionViewCell.swift"
                     ])
    #else
      return .target(name: "Astrolabe",  dependencies: [
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift")
      ], path: "./Sources/Core")
    #endif
  }
}

let package = Package(
    name: "Astrolabe",
    platforms: [
      .iOS(.v13),
      .tvOS(.v13)
    ],
    products: [
      .library(name: "Astrolabe", targets: ["Astrolabe"]),
      .library(name: "AstrolabeLoaders", targets: ["AstrolabeLoaders"])
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.8.0")),
      .package(url: "https://github.com/Katterpillar/Gnomon", branch: "master")
    ],
    targets: [
      Target.astrolabe(),
      .target(name: "AstrolabeLoaders", dependencies: ["Astrolabe", "Gnomon", "RxSwift"], path: "./Sources/Loaders")
    ],
    swiftLanguageVersions: [.v5]
)
