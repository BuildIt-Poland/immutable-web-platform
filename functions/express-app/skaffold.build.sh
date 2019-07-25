#!/bin/bash
images=$(echo $IMAGES | tr " " "\n")
echo "generated images"
echo $IMAGES
BUILDER=./nix/development.nix

nix-build $BUILDER -A docker --argstr hash $IMAGES --max-jobs 100 --out-link ../docker-image
docker load -i ../docker-image

nix-build $BUILDER -A yaml --argstr hash $IMAGES --out-link ../k8s-resource.yaml
