# Set all target’s visibility in this package to "public".
package(default_visibility = ["//visibility:public"])

# Load rules_haskell rules.
load(
    "@rules_haskell//haskell:defs.bzl",
    "haskell_toolchain_library",
    "haskell_library",
    "haskell_binary",
)

# haskell_toolchain_library can access builtin GHC packages
# and assign them a bazel target name, so that they
# can be referenced as dependencies.
haskell_toolchain_library(name = "base")

# You can add your own libraries with haskell_library.
# haskell_library(
#     name = "MY_LIBRARY_NAME",
#     src_strip_prefix = "src",
#     srcs = glob(['src/**/*.hs']),
#     deps = [
#         "base_pkg"
#     ],
# )

# An example binary using the Prelude module from the
# GHC base package, to print the hello world.
haskell_binary(
    name = "example",
    srcs = [":Example.hs"],
    deps = [":base"],
)

# DOCKER & KUBERNETES
# java_image(
#     name = "docker",
#     main_class = "com.ubs.wmap.eisl.data_policy.service.DataPolicyApp",
#     runtime_deps = [
#         ":runner",
#     ],
# )

# kubernetes_cluster_action(
#     "k8s_update",
#     "deployment/data-policy-service-deployment",
#     glob(["k8s/**/*.yaml"]),
#     ":docker.tar",
# )

# kubernetes_cluster_action(
#     "k8s_delete",
#     "deployment/data-policy-service-deployment",
#     glob(["k8s/**/*.yaml"]),
# )

