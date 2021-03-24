docker buildx create --name mybuilder --use
docker buildx build --platform linux/arm/v7 -t epandi/asterisk-freepbx-arm:17.15.2 --output type=tar,dest=release.tar .
