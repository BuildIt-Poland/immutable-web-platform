# https://nixos.org/nixops/manual/
# https://github.com/NixOS/nixops/blob/28231a177d751e800af3223a8763ea75b0ef9dd9/examples/vpc.nix
let

  pkgs = import <nixpkgs> {};

  region = "eu-west-2";
  accessKeyId = "default";
  project = "buildit-ops";
  maintainer = "damian.baar@wipro.com";

  vpcName = "${project}-vpc";
  sgName = "${project}-sg";
  igwName = "${project}-igw";

  tags = {
    inherit project;
    inherit maintainer;
  };

  subnets = [
    { name = "${vpcName}-subnet-a"; cidr = "10.0.0.0/19"; zone = "${region}a"; }
    { name = "${vpcName}-subnet-b"; cidr = "10.0.32.0/19"; zone = "${region}b"; }
    { name = "${vpcName}-subnet-c"; cidr = "10.0.64.0/19"; zone = "${region}c"; }
  ];

  ec2 =
    { resources, ... }:
    { 
      deployment.ec2.tags = tags;
      deployment.targetEnv = "ec2";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.region = region;
      deployment.ec2.instanceType = "t2.micro";
      deployment.ec2.keyPair = resources.ec2KeyPairs.deployment-key;

      deployment.ec2.ebsInitialRootDiskSize = 40; # GB

      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.subnetId = resources.vpcSubnets."${vpcName}-subnet-a";
      deployment.ec2.securityGroups = []; # INFO: we don't want its default `[ "default" ]`
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups."${sgName}".name ];
    };

in
{ 
  network.description = "Buildit-ops deployment";
  network.enableRollback = true;

  resources.vpc."${vpcName}" = {
    inherit accessKeyId region tags;

    instanceTenancy = "default";
    enableDnsSupport = true;
    enableDnsHostnames = true;
    cidrBlock = "10.0.0.0/16";
  };

  resources.vpcSubnets =
    let
      makeSubnet = { cidr, zone }: { resources, ... }: {
        inherit region zone accessKeyId tags;
        vpcId = resources.vpc."${vpcName}";
        cidrBlock = cidr;
        mapPublicIpOnLaunch = true;
      };
    in
      builtins.listToAttrs
        (map
          ({ name, cidr, zone }: pkgs.lib.nameValuePair name (makeSubnet { inherit cidr zone; }) )
          subnets
        );

  resources.vpcRouteTables = {
    route-table = { resources, ... }: {
      inherit region accessKeyId tags;
      vpcId = resources.vpc."${vpcName}";
    };
  };

  resources.vpcRoutes = {
    igw-route = { resources, ... }: {
      inherit region accessKeyId tags;
      routeTableId = resources.vpcRouteTables.route-table;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways."${igwName}";
    };
  };

  resources.vpcRouteTableAssociations =
    let
      association = subnetName: { resources, ... }: {
        inherit region accessKeyId tags;
        subnetId = resources.vpcSubnets."${subnetName}";
        routeTableId = resources.vpcRouteTables.route-table;
      };
    in
      builtins.listToAttrs
        (map
          ({ name, ... }: pkgs.lib.nameValuePair "association-${name}" (association name) )
          subnets
        );

  resources.vpcInternetGateways."${igwName}" = { resources, ... }: {
    inherit region accessKeyId tags;
    vpcId = resources.vpc."${vpcName}";
  };

  resources.ec2SecurityGroups."${sgName}" = 
    { resources, lib, ... }: {
      inherit accessKeyId region tags;

      vpcId = resources.vpc."${vpcName}";
      rules = [
        { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; } # SSH
        { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; } # HTTP
        { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; } # HTTPS
      ];
    };

  # Provision an EC2 key pair.
  resources.ec2KeyPairs.deployment-key =
    { inherit region accessKeyId tags; };

  buildit-ops = ec2;
}