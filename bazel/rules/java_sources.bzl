def java_sources(visibility = None):
    native.filegroup(
        name = "src_main",
        srcs = ["BUILD"] + native.glob(["src/main/java/**/*.java"]),
    )
    native.filegroup(
        name = "src_deploy",
        srcs = ["BUILD"] + native.glob(["src/deploy/java/**/*.java"]),
    )
    native.filegroup(
        name = "src_test",
        srcs = ["BUILD"] + native.glob(["src/test/java/**/*.java"]),
    )
    native.filegroup(
        name = "resources_main",
        srcs = native.glob(["src/main/resources/**"]),
    )
    native.filegroup(
        name = "resources_deploy",
        srcs = native.glob(["src/deploy/resources/**"]),
    )
    native.filegroup(
        name = "resources_test",
        srcs = native.glob(["src/test/resources/**"]),
    )
    native.filegroup(
        name = "src_benchmark",
        srcs = native.glob(["src/benchmark/java/**"]),
    )
