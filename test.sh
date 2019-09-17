result=nook

while [[ $result != ok ]]; do
  echo waiting for host
  result=$(ssh -o StrictHostKeyChecking=no root@18.130.247.181 echo ok 2>&1)
  echo $result
  sleep 1
done
