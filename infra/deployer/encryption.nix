# pkgs.sops
# ENCODE / DECODE
# use --before-upload to encode data before uploading
# pipe when download-state and decode

# encode-state = pkgs.writeScript "encode-state" ''
#   ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
# '';

# decode-state = pkgs.writeScript "decode-state" ''
#   ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
# '';