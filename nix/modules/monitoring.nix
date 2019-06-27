{ kubenix, ... }:
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
  ];
} 