# This file was generated with kubenix k8s generator, do not edit
{lib, config, ... }:

with lib;

let
  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo = coercedType: coerceFunc: finalType:
    mkOptionType rec {
      name = "coercedTo";
      description = "${finalType.description} or ${coercedType.description}";
      check = x: finalType.check x || coercedType.check x;
      merge = loc: defs:
        let
          coerceVal = val:
            if finalType.check val then val
            else let
              coerced = coerceFunc val;
            in assert finalType.check coerced; coerced;

        in finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
      getSubOptions = finalType.getSubOptions;
      getSubModules = finalType.getSubModules;
      substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
      typeMerge = t1: t2: null;
      functor = (defaultFunctor name) // { wrapped = finalType; };
    };
  };

  submoduleOf = ref: types.submodule ({name, ...}: {
    options = definitions."${ref}".options;
    config = definitions."${ref}".config;
  });

  definitions = {

    "istio_networking_v1alpha3_Gateway" = {
      options = {
        "selector" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
          default = "dsadas";
        };

        "servers" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Server_2")));
        };
      };

      config = {
        "selector" = mkOverride 1002 null;

        "servers" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Server_2" = {
      options = {
        "hosts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
          default = [];
        };

        # "port" = mkOption {
        #   description = "";
        #   type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Port"));
        # };

        # "tls" = mkOption {
        #   description = "";
        #   type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Server_TLSOptions"));
        # };
      };

      config = {
        "hosts" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "tls" = mkOverride 1002 null;
      };
    };
  };
in {
  options = {
    "gateways" = mkOption {
      description = "";
      type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Gateway")));
    };
  };
  config = {
    kubernetes.customResources = [
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "Gateway";
      description = "";
      resource = "istioo";
      module = definitions."istio_networking_v1alpha3_Gateway";
    }
  ];
  };
}