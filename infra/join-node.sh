
# TODO generate based on machines.json
nixops ssh -d cluster worker-0 $(nixops ssh -d cluster master-0 get-join-command)
