load("@io_bazel_rules_docker//java:image.bzl", "java_image")
load("@checkstyle_java//checkstyle:checkstyle.bzl", "checkstyle_test")
load("@io_bazel_rules_k8s//k8s:object.bzl", "k8s_object")
load("@rules_jmh//:defs.bzl", "jmh_java_benchmarks")
load("//config:bazel.bzl", "uniq", "api", "jmh_deps", "logging_deps", "common_logging_deps", "web", "test_web")
load("//tools/build_rules:development.bzl", "generate_artifact_pom", "kubernetes_cluster_action")

package(default_visibility = ["//visibility:public"])

java_sources()

java_library(
    name = "service",
    srcs = [":src_main"],
    resources = [":resources_main"],
    deps = uniq(api + web)
)

java_binary(
    name = "runner",
    main_class = "com.ubs.wmap.eisl.logging.service.LoggingService",
    runtime_deps = [
        ":service",
    ],
)

java_test(
    name = "test",
    size = "enormous",
    timeout = "moderate",
    flaky = True,
    local = True,
    srcs = [":src_test"],
    data = ["//packages/logging/service/src/test/resources:test-deps"],
    resources = ["//packages/logging/service/src/test/resources:test-deps"],
    test_class = "com.ubs.wmap.eisl.logging.service.LoggingControllerTest",
    deps = [":service"] + test_web,
)

# JAVA CHECKS
checkstyle_test(
    name = "service-checkstyle",
    allow_failure = 0,
    config = "//config:checkstyle.xml",
    target = ":service",
)

# TODO
# java_test(
#     name = "test",
#     size = "small",
#     srcs = [":src_test"],
#     test_class = "com.ubs.wmap.eisl.validation.ValidationTest",
#     deps = [
#         ":service",
#     ] + junit_deps,
# )

# DOCKER & KUBERNETES
java_image(
    name = "docker",
    main_class = "com.ubs.wmap.eisl.logging.service.LoggingService",
    runtime_deps = [
        ":service",
    ],
)

kubernetes_cluster_action(
    "k8s_update",
    "deployment/logging-service-deployment",
    glob(["k8s/**/*.yaml"]),
    ":docker.tar",
)

kubernetes_cluster_action(
    "k8s_delete",
    "deployment/logging-service-deployment",
    glob(["k8s/**/*.yaml"]),
)

generate_artifact_pom(
    targets = [":service"],
    mainClass = "com.ubs.wmap.eisl.logging.service.LoggingService",
    testClass = "com.ubs.wmap.eisl.logging.service.LoggingControllerTest",
)

generate_artifact_pom(
    targets = test_web,
    name = "pom_test",
)
