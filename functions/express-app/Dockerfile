FROM lnl7/nix:2.2.2 

ARG AWS_ACCESS_KEY_ID
ENV AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID

ARG AWS_SECRET_ACCESS_KEY
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

COPY . /src

WORKDIR /src/functions/express-app

RUN echo "require-sigs = false" >> /etc/nix/nix.conf
RUN echo "builders-use-substitutes = true" >> /etc/nix/nix.conf
RUN echo "binary-caches = 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2' https://cache.nixos.org/" >> /etc/nix/nix.conf

RUN ssh root@hydra.future-is-comming.dev.buildit.consulting nix-store --version

RUN nix-build ./nix/development.nix \
  -A package \
  --builders ssh://root@hydra.future-is-comming.dev.buildit.consulting \
  --option binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2 https://cache.nixos.org/' \
  --option trusted-public-keys 'hydra.future-is-comming.dev.buildit.consulting:Ym8un3mSkEesoPDZjm0cf8Kfn2B3a2QIesbHUw1GMvA=' \
  --max-jobs 0

# FROM node:latest as serve
# COPY --from=base /usr/sth /src/functions/express-app/result /usr/sth/test/
# RUN ls -la /usr/sth
