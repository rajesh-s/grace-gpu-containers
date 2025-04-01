# VLLM images for GH200

Hosted [here](https://hub.docker.com/repository/docker/rajesh550/gh200-vllm)

```bash
docker login
docker build --platform linux/arm64 -t rajesh550/gh200-vllm:0.8.1 .
docker push rajesh550/gh200-vllm:0.8.1
```
