FROM lnl7/nix:2.2.2 

ARG AWS_ACCESS_KEY_ID
ENV AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID

ARG AWS_SECRET_ACCESS_KEY
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

ARG ssh_prv_key
ARG ssh_pub_key

RUN nix-env -f '<nixpkgs>' -i openssh gnused

RUN mkdir -p /root/.ssh && \
  chmod 0700 /root/.ssh 

RUN echo "$ssh_prv_key" > /root/.ssh/id_rsa \
  && chmod 400 /root/.ssh/id_rsa

RUN echo "$ssh_pub_key" > /root/.ssh/id_rsa.pub \
  && chmod 600 /root/.ssh/id_rsa.pub

RUN ssh-keyscan -t rsa hydra.future-is-comming.dev.buildit.consulting 2>&1 >> /root/.ssh/known_hosts
RUN ssh-keyscan -t rsa 3.8.90.208 2>&1 >> /root/.ssh/known_hosts
# RUN echo "hydra.future-is-comming.dev.buildit.consulting ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2FeMx6YErqwF5KmH19hg6ebPlshNM2B+dyWHtFFxI+" >> /root/.ssh/known_hosts

COPY . /src

WORKDIR /src/functions/express-app

COPY ./functions/express-app/ssh-config /root/.ssh/config

# RUN ssh-keygen -f ~/.ssh/nix_remote
# RUN ssh-copy-id -i /root/.ssh/nix_remote root@hydra.future-is-comming.dev.buildit.consulting -f

RUN echo "require-sigs = false" >> /etc/nix/nix.conf
RUN echo "builders-use-substitutes = true" >> /etc/nix/nix.conf
# RUN echo "binary-caches = 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2' https://cache.nixos.org/" >> /etc/nix/nix.conf

RUN ssh -v root@3.8.90.208 nix-store --version

RUN nix build -f ./nix/development.nix \
  package \
  # --builders 'ssh://root@hydra.future-is-comming.dev.buildit.consulting x86_64-linux' \
  --builders 'ssh://root@3.8.90.208 x86_64-linux' \
  # --option trusted-public-keys 'hydra.future-is-comming.dev.buildit.consulting:Ym8un3mSkEesoPDZjm0cf8Kfn2B3a2QIesbHUw1GMvA=' \
  --option builders-use-substitutes true \
  --option extra-substituters ssh://3.8.90.208  \
  --option trusted-substituters ssh://3.8.90.208  \
  --option max-jobs 0 \
  -v
# --option binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2 https://cache.nixos.org/' \
# --option trusted-public-keys 'hydra.future-is-comming.dev.buildit.consulting:Ym8un3mSkEesoPDZjm0cf8Kfn2B3a2QIesbHUw1GMvA=' \
# --max-jobs 0

RUN rm -rf /root/.ssh/

# FROM node:latest as serve
# COPY --from=base /usr/sth /src/functions/express-app/result /usr/sth/test/
# RUN ls -la /usr/sth
