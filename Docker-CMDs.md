## Pull All Tags
```sh
$ docker image pull --all-tags minio/minio
```

## List All MinIO Docker Images
```sh
$ curl -s https://hub.docker.com/v2/repositories/minio/minio/tags/?page_size=100 | jq '.results[].name'
"latest"
"RELEASE.2025-06-13T11-33-47Z-cpuv1"
"RELEASE.2025-06-13T11-33-47Z"
"latest-cicd"
"RELEASE.2025-05-24T17-08-30Z-cpuv1"
~~ snip
```

## Run Docker with the specific version of MinIO
```sh
$ mkdir /data01

$ docker run -p 9000:9000 -p 9001:9001 --name minio \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z server /data --console-address ":9001"
```


## Configure MinIO Docker Systemd
```sh
$ vi /etc/systemd/system/minio-docker.service
[Unit]
Description=MinIO Docker Container
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /data01:/data \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=changeme \
  minio/minio server /data --console-address ":9001"

ExecStop=/usr/bin/docker stop minio
ExecReload=/usr/bin/docker restart minio
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Force Remove Docker Imgages at Once
```sh
$ docker stop minio && docker rm minio

$ for i in `docker images | sed 1d | awk '{print $3}'`; do docker image rm $i --force ; done
```

## Reference
https://abdelouahabmbarki.com/distributed-minio-docker/

