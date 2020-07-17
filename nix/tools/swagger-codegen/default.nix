{ stdenv, fetchurl, jre, makeWrapper }:

stdenv.mkDerivation rec {
  version = "3.0.18";
  pname = "swagger-codegen";

  jarfilename = "${pname}-cli-${version}.jar";

  nativeBuildInputs = [
    makeWrapper
  ];

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/${version}/swagger-codegen-cli-${version}.jar";
    sha256 = "1m62625pdsf3pmnl0npqakry54m4bamk59rsz7mi2lwj18nw89wy";
  };

  phases = [ "installPhase" ];

  # TODO this is so so - create wrapper script on top of java to handle it without need to recompile
  installPhase = ''
    install -D "$src" "$out/share/java/${jarfilename}"
    makeWrapper ${jre}/bin/java  $out/bin/swagger-codegen \
      --add-flags "-Dmodels" --add-flags "-jar $out/share/java/${jarfilename}"
  '';

  meta = with stdenv.lib; {
    description = "Allows generation of API client libraries (SDK generation), server stubs and documentation automatically given an OpenAPI Spec";
    homepage = https://github.com/swagger-api/swagger-codegen;
    license = licenses.asl20;
    maintainers = [ maintainers.jraygauthier ];
  };
}
