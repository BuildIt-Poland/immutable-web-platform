
# # "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"; # FIXME someday ... sth is not working with nlb
# "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Owner=${cfg.project.authorEmail}";
# "external-dns.alpha.kubernetes.io/hostname" = "${name}.${cfg.project.domain}";