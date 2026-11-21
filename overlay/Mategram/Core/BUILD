load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MategramCore",
    module_name = "MategramCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [],
    visibility = [
        "//visibility:public",
    ],
)
