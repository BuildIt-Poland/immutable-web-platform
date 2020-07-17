load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_skylib//lib:selects.bzl", "selects")

uniq = collections.uniq
with_or = selects.with_or

#############
#### CONFIG
############

namespace = "com.ubs.wmap.eisl"
version = "0.0.1-SNAPSHOT"

#############
#### BASE
############

lombok = [
    "@maven//:org_projectlombok_lombok",
    "//:lombok",
]

guava = [ "@maven//:com_google_guava_guava" ]

immutables_base = guava + [
  "@maven//:org_immutables_value",
  "@maven//:org_immutables_builder",
  "@maven//:org_immutables_func",
  "@maven//:org_immutables_value_processor",
  "@maven//:org_immutables_value_annotations",
  "@maven//:org_immutables_generator",
  "@maven//:org_immutables_generator_processor",
]

immutables = immutables_base;

jackson = [
    "@maven//:com_fasterxml_jackson_core_jackson_annotations",
    "@maven//:com_fasterxml_jackson_core_jackson_core",
    "@maven//:com_fasterxml_jackson_core_jackson_databind",
    "@maven//:com_fasterxml_jackson_dataformat_jackson_dataformat_yaml",
    "@maven//:com_fasterxml_jackson_datatype_jackson_datatype_jdk8",
    "@maven//:com_fasterxml_jackson_datatype_jackson_datatype_guava"
]

fp_deps = [
    "@maven//:io_vavr_vavr",
    "@maven//:org_functionaljava_functionaljava",
    "@maven//:org_functionaljava_functionaljava_java8",
    "@maven//:org_functionaljava_functionaljava_java_core"
]

reactive_core = [
    "@maven//:io_projectreactor_reactor_core",
    "@maven//:org_reactivestreams_reactive_streams"
]

yaml_props = [ "@maven//:org_yaml_snakeyaml" ]


validation = [
  "@maven//:javax_validation_validation_api",
  "@maven//:org_springframework_spring_context",
  "@maven//:org_springframework_boot_spring_boot_starter_validation"
]

swagger = validation + [
  "@maven//:javax_annotation_javax_annotation_api",
  "@maven//:io_swagger_swagger_annotations",
]

# TODO check if we do not have too much libs to json
json_path = [
   "@maven//:commons_jxpath_commons_jxpath",
   "@maven//:com_jayway_jsonpath_json_path",
   "@maven//:net_minidev_json_smart",
]

base = uniq(immutables + lombok + jackson + fp_deps + reactive_core + yaml_props + guava + json_path)

#############
#### SERVERS
############

mock_server = [
    "@maven//:com_squareup_okhttp3_okhttp",
    "@maven//:com_squareup_okhttp3_mockwebserver",
]

netty = [
    "@maven//:io_projectreactor_netty_reactor_netty",
    "@maven//:org_glassfish_jakarta_el",
    "@maven//:org_synchronoss_cloud_nio_multipart_parser",
]

#############
#### SPRING & FRIENDS
############

spring = [
  "@maven//:org_springframework_spring_aspects",
  "@maven//:org_springframework_spring_core",
  "@maven//:org_springframework_spring_web",
  "@maven//:org_springframework_spring_context",
  "@maven//:org_springframework_spring_beans",
  "@maven//:org_springframework_spring_messaging",
  "@maven//:org_springframework_spring_expression",
]

webflux = netty + [
    "@maven//:org_springframework_spring_webflux",
    "@maven//:org_springframework_boot_spring_boot_starter_webflux",
    "@maven//:org_springframework_boot_spring_boot_starter_reactor_netty",
]

springboot_starter = [
    "@maven//:org_springframework_boot_spring_boot_starter",
    "@maven//:org_springframework_boot_spring_boot_starter_log4j2",
]

springboot = springboot_starter + [
    "@maven//:org_springframework_boot_spring_boot",
    "@maven//:org_springframework_boot_spring_boot_autoconfigure",
    "@maven//:org_springframework_boot_spring_boot_configuration_processor",
    "@maven//:org_springframework_boot_spring_boot_autoconfigure",
]

springboot_web = [
  "@maven//:org_springframework_boot_spring_boot_starter_web",
]

resilience = [
    "@maven//:io_github_resilience4j_resilience4j_all",  # Optional, only required when you want to use the Decorators class
    "@maven//:io_github_resilience4j_resilience4j_ratelimiter",
    "@maven//:io_github_resilience4j_resilience4j_bulkhead",
    "@maven//:io_github_resilience4j_resilience4j_timelimiter",
    "@maven//:io_github_resilience4j_resilience4j_retry",
    "@maven//:io_github_resilience4j_resilience4j_core",
    "@maven//:io_github_resilience4j_resilience4j_circuitbreaker",
    "@maven//:io_github_resilience4j_resilience4j_annotations",
    "@maven//:io_github_resilience4j_resilience4j_spring_boot2",
    "@maven//:io_github_resilience4j_resilience4j_reactor",
    "@maven//:org_springframework_cloud_spring_cloud_commons",
    "@maven//:org_springframework_cloud_spring_cloud_circuitbreaker_resilience4j",
    "@maven//:org_springframework_cloud_spring_cloud_starter_circuitbreaker_resilience4j",
    "@maven//:org_springframework_cloud_spring_cloud_starter_circuitbreaker_reactor_resilience4j",
]

deploy = [
    "@maven//:org_springframework_cloud_spring_cloud_dataflow_rest_client",
    "@maven//:org_springframework_cloud_spring_cloud_dataflow_core",
]

reactive_test = [
    "@maven//:io_projectreactor_reactor_test",
]

ftp = [
        "@maven//:commons_net_commons_net",
        "@maven//:commons_io_commons_io",
]

ftp_test = [
        "@maven//:org_mockftpserver_MockFtpServer",
]

springboot_actuator = [
    "@maven//:org_springframework_boot_spring_boot_starter_actuator",
]

kafka_test_deps = [
    "@maven//:org_springframework_kafka_spring_kafka_test",
]

spring_cloud_test = [
    "@maven//:org_springframework_cloud_spring_cloud_stream_test_binder",  # test_binder is a classifier
    "@maven//:org_springframework_cloud_spring_cloud_stream_binder_test",
]

spring_cloud = [
    "@maven//:org_springframework_cloud_spring_cloud_stream_binder_kafka",
    "@maven//:org_springframework_cloud_spring_cloud_stream_binder_kafka_streams",
    "@maven//:org_springframework_cloud_spring_cloud_stream",
    "@maven//:org_springframework_integration_spring_integration_core",
    "@maven//:org_springframework_spring_messaging",
]

reactive = [
    "@maven//:io_projectreactor_reactor_core",
]

junit_deps = [
    "@maven//:org_mockito_mockito_core",
    "@maven//:org_assertj_assertj_core",
    "@maven//:junit_junit",
]

springboot_test = [
    "@maven//:org_springframework_boot_spring_boot_test",
    "@maven//:org_springframework_spring_test",
    "@maven//:org_springframework_boot_spring_boot_test_autoconfigure",
]

jmh_deps = [
    "@maven//:org_openjdk_jmh_jmh_core",
    "@maven//:org_openjdk_jmh_jmh_generator_annprocess",
]

audit_core_deps = [
#  "@maven//:org_javers_javers_spring_boot_starter_sql",
  "@maven//:org_javers_javers_core",
]

awaitility = [
    "@maven//:org_awaitility_awaitility",
]

kafka_deps = [
    "@maven//:org_apache_kafka_kafka_clients",
    "@maven//:org_apache_kafka_kafka_streams",
    "@maven//:org_springframework_kafka_spring_kafka",
]

db_classic = [
  "@maven//:com_h2database_h2",
  "@maven//:org_postgresql_postgresql",
  "@maven//:org_apache_derby_derby",
]

db_reactive_deps = [
  "@maven//:io_r2dbc_r2dbc_postgresql",
  "@maven//:io_r2dbc_r2dbc_h2",
  "@maven//:io_r2dbc_r2dbc_pool",
  "@maven//:io_r2dbc_r2dbc_spi",
  "@maven//:org_springframework_data_spring_data_r2dbc",
]

jpa = [
  "@maven//:org_springframework_boot_spring_boot_starter_data_jpa",
  "@maven//:org_springframework_data_spring_data_jpa",
  "@maven//:org_hibernate_javax_persistence_hibernate_jpa_2_0_api",
  "@maven//:org_springframework_spring_orm",
  "@maven//:org_hibernate_hibernate_core",
  "@maven//:org_hibernate_hibernate_entitymanager",
  "@maven//:org_springframework_data_spring_data_commons",
  "@maven//:org_springframework_data_spring_data_relational",
]

data_persistence_reactive_deps = [
  "@maven//:org_springframework_data_spring_data_relational",
  "@maven//:org_springframework_data_spring_data_r2dbc",
  "@maven//:org_springframework_data_spring_data_commons",
]

reactive_db = uniq(data_persistence_reactive_deps + db_reactive_deps)
jpa_db = uniq(db_classic + jpa)

easy_rules_deps = [
    "@maven//:org_jeasy_easy_rules_core",
    "@maven//:org_jeasy_easy_rules_mvel",
    "@maven//:org_jeasy_easy_rules_support",
]

graphqli_deps = [
    "@maven//:com_graphql_java_kickstart_graphiql_spring_boot_starter",
    "@maven//:com_graphql_java_kickstart_graphiql_spring_boot_autoconfigure",
]

graphql_deps = [
    "@maven//:com_graphql_java_graphql_java",
    "@maven//:com_graphql_java_graphql_java_extended_scalars",
    "@maven//:com_graphql_java_kickstart_graphql_java_tools",
    "@maven//:com_graphql_java_kickstart_graphql_spring_boot_starter",
    "@maven//:com_graphql_java_kickstart_graphql_kickstart_spring_boot_starter_webflux",
    "@maven//:com_graphql_java_kickstart_graphql_kickstart_spring_boot_autoconfigure_webflux",
] + graphqli_deps

graphql_deps_test = graphql_deps + [
    "@maven//:com_graphql_java_kickstart_graphql_spring_boot_starter_test",
    "@maven//:com_graphql_java_kickstart_graphql_spring_boot_test",
    "@maven//:com_graphql_java_kickstart_graphql_spring_boot_test_autoconfigure",
    "@maven//:commons_io_commons_io",
]

elasticsearch_deps = [
    "@maven//:org_elasticsearch_client_elasticsearch_rest_high_level_client",
    "@maven//:org_elasticsearch_client_elasticsearch_rest_client",
    "@maven//:org_apache_httpcomponents_httpcore",
    "@maven//:org_elasticsearch_elasticsearch"
]

common_logging_deps = [
    "@maven//:org_apache_logging_log4j_log4j_api",
    "@maven//:org_apache_logging_log4j_log4j_core",
    "@maven//:com_lmax_disruptor",
#    "@maven//:org_slf4j_slf4j_api",
    "@maven//:org_apache_logging_log4j_log4j_slf4j_impl",
]

reactive_stream = [
    "@maven//:io_projectreactor_kafka_reactor_kafka",
]

kafka = [
    "@maven//:org_springframework_kafka_spring_kafka",
    "@maven//:org_apache_kafka_kafka_clients",
    "@maven//:org_apache_kafka_kafka_streams",
]

#############
#### TESTING
############

zerocode = [
  "@maven//:org_apache_httpcomponents_httpclient",
  "@maven//:org_apache_httpcomponents_httpcore",
  "@maven//:org_jsmart_zerocode_tdd",
]

#############
#### SDK
############

validation_service = [
    "//packages/validation/service/validation_service:validation_service",
]

rules_repository = [
    "//packages/validation/starter/rules_engine_spring_boot_starter",
    "//packages/validation/library/rules_engine",
]

data_model = [
    "//packages/data_model"
]

data_model_deps = jackson + swagger

exception_deps = [
    "//packages/exception_management/core",
]

data_lineage_deps = [
    "//packages/data_lineage/core",
]

audit_deps = [
    "//packages/audit/core",
] + audit_core_deps

logging_deps = [
    "//packages/logging/core",
]

eisl_service_deps = [
  "//packages/eisl_service/core",
  "//packages/eisl_service/service",
  "//packages/eisl_service/api",
]

test_helpers = [
  # new way
  "//packages/test_helpers",
]

services_core = exception_deps + data_lineage_deps + audit_deps + logging_deps;

commons = uniq([
  "//packages/common/configuration",
  "//packages/common/helper",
  "@maven//:org_apache_commons_commons_lang3",
] + exception_deps + data_model_deps + audit_deps + logging_deps)

#############
#### BUNDLES
############
globals = uniq(
  commons
)

model = uniq(
    common_logging_deps
  + logging_deps
  + jackson
  + data_model
  + swagger
)

api = uniq(
    model
  + eisl_service_deps
  + commons
)

web = uniq(
    base
  + api
  + spring
  + springboot
  + resilience
  + springboot_web
  + springboot_actuator
#  + jpa
  + webflux
)

library = uniq(
    base
  + spring
  + logging_deps
  + common_logging_deps
  + springboot
  + resilience
)

test__ = uniq(
    junit_deps
  + springboot_test
  + model
  + mock_server
)

test = uniq(
    junit_deps
  + model
  + springboot_test
  + test_helpers
)

test_web_ = uniq(
    web
  + test
  + springboot_web
  + mock_server
)

test_web = uniq(
    test_web_
  + test_helpers
)

stream = uniq(
    api
  + web
  + spring
  + kafka
  + spring_cloud
  + common_logging_deps
  + reactive_stream
)

cloud = uniq(
    stream
  + spring_cloud
  + reactive_stream
)

test_stream = uniq(
    base
  + test_web
  + spring_cloud_test
  + kafka_test_deps
  + stream
)

test_webflux = uniq(
  test_stream + webflux
)

test_integration = uniq(
    zerocode
)

webstream = uniq(
    web
  + stream
  + webflux
  + cloud
)

perf = uniq(
    test_web
  + jmh_deps
)

db_support = uniq(
    db_classic
  + jpa_db
)

db_support_reactive = uniq(
    db_classic
  + reactive_core
  + reactive_db
)


