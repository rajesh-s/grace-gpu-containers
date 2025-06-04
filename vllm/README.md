# VLLM images for GH200

Hosted [here](https://hub.docker.com/repository/docker/rajesh550/gh200-vllm)

```bash
docker login
docker buildx build --platform linux/arm64 --memory=600g -t rajesh550/gh200-vllm:0.9.0.1 .

docker build --memory=300g -t rajesh550/gh200-vllm:0.9.0.1 .
docker push rajesh550/gh200-vllm:0.9.0.1
```
