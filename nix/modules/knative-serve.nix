{ lib, kubenix, ... }:
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

  mkOptionDefault = mkOverride 1001;

  extraOptions = {
    kubenix = {};
  };

  mergeValuesByKey = mergeKey: values:
    listToAttrs (map
      (value: nameValuePair (
        if isAttrs value.${mergeKey}
        then toString value.${mergeKey}.content
        else (toString value.${mergeKey})
      ) value)
    values);

  submoduleOf = ref: types.submodule ({name, ...}: {
    options = definitions."${ref}".options;
    config = definitions."${ref}".config;
  });

  submoduleWithMergeOf = ref: mergeKey: types.submodule ({name, ...}: let
    convertName = name:
      if definitions."${ref}".options.${mergeKey}.type == types.int
      then toInt name
      else name;
  in {
    options = definitions."${ref}".options;
    config = definitions."${ref}".config // {
      ${mergeKey} = mkOverride 1002 (convertName name);
    };
  });

  submoduleForDefinition = ref: resource: kind: group: version:
    types.submodule ({name, ...}: {
      options = definitions."${ref}".options // extraOptions;
      config = mkMerge ([
        definitions."${ref}".config
        {
          kind = mkOptionDefault kind;
          apiVersion = mkOptionDefault version;

          # metdata.name cannot use option default, due deep config
          metadata.name = mkOptionDefault name;
        }
      ] ++ (config.defaults.${resource} or [])
        ++ (config.defaults.all or []));
    });

  coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: (types.coercedTo
    (types.listOf (submoduleOf ref))
    (mergeValuesByKey mergeKey)
    (types.attrsOf (submoduleWithMergeOf ref mergeKey))
  );

  definitions = {
  "knative" = {
      options = {
        "host" = {
          # description = "";
          type = (types.nullOr types.str);
        };

        # "subsets" = mkOption {
        #   description = "";
        #   type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Subset")));
        # };

        # "trafficPolicy" = mkOption {
        #   description = "";
        #   type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_TrafficPolicy"));
        # };
      };

      config = {
        "host" = mkOverride 1002 null;

        "subsets" = mkOverride 1002 null;

        "trafficPolicy" = mkOverride 1002 null;
      };
    };
  };
in
rec {
  # imports = with kubenix.modules; [ k8s ];
  imports = [ kubenix.modules.submodule ];

  # TODO
  # options.knative = lib.mkOption {
  #   options.api = lib.mkOption {
  #     options.services = {

  #     };
  #   };
  #   default = {};
  # };

  config = rec {
     _module.features = [ "k8s" ];

    kubernetes.customResources = [
      {
        group = "serving.knative.dev";
        version = "v1alpha1";
        kind = "Service";
        description = "";
        module = definitions."knative";
        resource = "knative";
      }
    ];
  };
} 