// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "SapiMeasurementCore", products: [.library(name:"SapiMeasurementCore",targets:["SapiMeasurementCore"])], targets: [.target(name:"SapiMeasurementCore",path:"Core"),.testTarget(name:"SapiMeasurementCoreTests",dependencies:["SapiMeasurementCore"],path:"Tests")])
