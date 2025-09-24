# VLLM images for GH200

Hosted [here](https://hub.docker.com/repository/docker/rajesh550/gh200-vllm)

```bash
sudo docker login
# Alternative
# docker buildx build --platform linux/arm64 --memory=600g -t rajesh550/gh200-vllm:0.9.0.1 .
sudo docker build --memory=300g --platform linux/arm64 -t rajesh550/gh200-vllm:0.10.2 .  
sudo docker push rajesh550/gh200-vllm:0.10.2
```