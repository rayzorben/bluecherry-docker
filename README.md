# bluecherry-docker
Docker build scripts for bluecherry NVR.

Currently this docker image is building the source off from a forked version in order to add support for MYSQL running in a different container. To build this, perform the following:

1. clone this repository with `git clone https://github.com/rayzorben/bluecherry-docker.git`
2. modify `.env` and specify the variable values. The only one that is of concern to change is `MYSQL_ADMIN_PASSWORD`
3. Start mysql image with `docker-compose up -d mysql`
4. Build the bluecherry image with `docker-compose build`
5. Start bluecherry with `docker-compose up -d bluecherry`

You should be able to access the bluecherry server interface on http://localhost:7001
