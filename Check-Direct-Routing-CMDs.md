# HAProxy Node
```sh
$ tcpdump -i any host minio-api.jtest.pivotal.io and port 9000
$ conntrack -L | grep 9000
```

# Backend Node
```sh
$ tcpdump -i any host 192.168.1.3 <client ip> and port 9000
```

