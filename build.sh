VERSION_TAG=v0.2.16

docker build --build-arg GIT_TAG=$VERSION_TAG -t shenlw/morphic:$VERSION_TAG .
docker build --build-arg GIT_TAG=$VERSION_TAG -t shenlw/morphic:latest .

docker push shenlw/morphic:$VERSION_TAG
docker push shenlw/morphic:latest
