load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MategramUI",
    module_name = "MategramUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Mategram/Core:MategramCore",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/UndoUI:UndoUI",
        "//submodules/SettingsUI:SettingsUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
