# https://nixos.org/nixops/manual/
# https://github.com/NixOS/nixops/blob/28231a177d751e800af3223a8763ea75b0ef9dd9/examples/vpc.nix
let

  pkgs = import <nixpkgs> {};

  region = "eu-west-2";
  accessKeyId = "default";
  project = "buildit-ops";
  maintainer = "damian.baar@wipro.com";

  sgName = "${project}-sg";
  vpcName = "${project}-vpc";
  igwName = "${project}-igw";

  tags = {
    inherit project;
    inherit maintainer;
    Owner = maintainer; # cloud-custodian requires upper case
  };

  subnets = [
    { name = "${vpcName}-subnet-a"; cidr = "10.0.0.0/19"; zone = "${region}a"; }
  ];

  ec2 =
    { resources, ... }:
    with pkgs;
    { 
      # imports = [
      #   cgroups-v2 patch
      # ];
      ec2.hvm = true;
      # https://github.com/NixOS/nixops/issues/1181
      # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/amazon-image.nix#L54
      # naming: /dev/nvme*1 https://aws.amazon.com/blogs/aws/ec2-instance-update-c5-instances-with-local-nvme-storage-c5d/
      boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
      # boot.initrd.postMountCommands = ''
      #   ln /dev/nvme0n1 /dev/xvda
      # '';

      deployment.ec2.tags = tags;
      deployment.targetEnv = "ec2";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.region = region;
      # https://aws.amazon.com/ec2/spot/pricing/
      # t2.medium - $0.0139 per Hour = 1,39 cents
      # deployment.ec2.instanceType = "t2.medium"; 
      # deployment.ec2.spotInstancePrice = 2;

      # https://github.com/NixOS/nixops/blob/master/nix/ec2-properties.nix
      # https://github.com/NixOS/nixops/blob/master/nix/ec2.nix#L153j
      # deployment.ec2.instanceType = "m4.xlarge";
      deployment.ec2.instanceType = "c5d.large";

      # you cannot stop spot instances - so as far is won't be solved disabling
      # https://github.com/NixOS/nixops/issues/1181
      # deployment.ec2.spotInstancePrice = 5;
      # deployment.ec2.spotInstanceTimeout = 5 * 60;
      # deployment.ec2.spotInstanceInterruptionBehavior = "hibernate";
      # deployment.ec2.spotInstanceRequestType = "persistent";

      deployment.ec2.keyPair = resources.ec2KeyPairs.deployment-key;

      deployment.ec2.ebsInitialRootDiskSize = 40; # GB

      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.subnetId = resources.vpcSubnets."${vpcName}-subnet-a";
      deployment.ec2.securityGroups = []; # INFO: we don't want its default `[ "default" ]`
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups."${sgName}".name ];
    };
in
{ 
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

  resources.ec2KeyPairs.deployment-key =
    { inherit region accessKeyId tags; };

  buildit-tester = ec2;
}