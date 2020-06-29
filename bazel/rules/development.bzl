load("//config:bazel.bzl", "namespace", "version")
load("//tools/build_rules:generate_pom.bzl", "pom_file")
load("@checkstyle_java//checkstyle:checkstyle.bzl", "checkstyle_test")

def kubernetes_cluster_action(name, service_name, data, target = "", deps = []):
    native.sh_test(
        name = name,
        data = data + [target] if target != "" else [],
        deps = deps,
        args = [("$(location " + target + ")"), service_name] if target else [service_name],
        srcs = ["//tools/build_rules:" + name + ".sh"],
        tags = ["manual"],
    )

def upload_docker_image(name, target, tag, deps = [], extraArgs = []):
    native.sh_test(
        name = name,
        data = [target] if target != "" else [],
        deps = deps,
        args = [("$(location " + target + ")"), tag] + extraArgs,
        srcs = ["//tools/build_rules:upload_docker_image.sh"],
        tags = ["manual"],
    )

def generate_artifact_pom(targets, name = "", generateParent = False, mainClass = "", testClass = ""):
    pom_file(
        name = name if name != "" else "pom",
        artifact_config = {
            "group_id": namespace,
            "version": version,
            "main_class": mainClass,
            "test_class": testClass,
        },
        generate_parent = generateParent,
        targets = targets,
        excluded_artifacts = ["com.ubs.wmap.eisl.:lombok"],
        template_file = "//tools/templates/pom:artifact_pom.xml",
    )

def checkstyle(name, target):
    checkstyle_test(
        name = name + "-checkstyle",
        allow_failure = 0,
        config = "//config:checkstyle.xml",
        target = target,
    )

def artifact_with_version(name, jar, version):
    native.genrule(
        name = name,
        outs = ["%s-%s.jar" % (name, version)],
        srcs = [jar],
        cmd = "cp $< $@",
    )
