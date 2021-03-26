docker buildx create --name mybuilder --use
docker buildx build --platform linux/arm/v7 -t epandi/asterisk-freepbx-arm:18.15-alpha --output type=tar,dest=release.tar .
