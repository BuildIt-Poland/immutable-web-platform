# TODO
openapi-template = nixpkgs.fetchFromGitHub {
    owner = "deviantlycan";
    repo = "openapi-generator-templates";
    rev = "8d39ba1207bd86160e9cd655fe36167e0d3bb99e";
    sha256 = "0l0iqnbm0f1kh50nf2hj3x68d8l0mlrjy14gykif0shl5qcg06y9";
  };

  generate_api = name: config: extraArgs: nixpkgs.writeScriptBin "generate_api_${name}" ''
    temp="$3"
    mkdir -p $temp/src
    ${nixpkgs.swagger-codegen}/bin/swagger-codegen \
        generate -i $temp/schema.yaml -o $temp -l $2  \
          -c ${rootFolder}/config/${config}.json  \
          -t ${rootFolder}/template/${name} \
          --template-engine handlebars ${extraArgs}
  '';