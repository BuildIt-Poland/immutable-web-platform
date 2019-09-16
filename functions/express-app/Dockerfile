FROM lnl7/nix:2.2.2

RUN nix-env -iA jq

COPY . /src

WORKDIR /src/functions/express-app

RUN echo "require-sigs = false" >> /etc/nix/nix.conf
# one linux store, second one normal store
# !!! only s3 binary cache
RUN echo "binary-caches = http://localhost:5000 http://localhost:5001 https://cache.nixos.org/" >> /etc/nix/nix.conf

# RUN nix-store --repair --verify

RUN nix-build nix/development.nix -A package

RUN nix path-info -r --json ./result | jq .

# FROM mhart/alpine-node:12
# COPY --from=builder /src/functions/express-app/result /app
# RUN ls -la
# RUN ls -la /app
# # # Cmd = ["start-server"];
# # # WorkingDir = "${express-app}";
# # # ExposedPorts = {
# # #   "${toString fn-config.port}/tcp" = {};
# # # };
