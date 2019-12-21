#######################################################
# set a base image with environment to build from
#######################################################
FROM ubuntu:18.04 AS scratch
ARG MYSQL_HOST
ARG MYSQL_ADMIN_LOGIN
ARG MYSQL_ADMIN_PASSWORD
ARG BLUECHERRY_DB_USER
ARG BLUECHERRY_DB_PASSWORD
ARG BLUECHERRY_DB_NAME
ARG BLUECHERRY_USERHOST
ARG BLUECHERRY_GROUP_ID
ARG BLUECHERRY_USER_ID

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ADMIN_LOGIN=$MYSQL_ADMIN_LOGIN
ENV MYSQL_ADMIN_PASSWORD=$MYSQL_ADMIN_PASSWORD
ENV dbname=$BLUECHERRY_DB_NAME
ENV host=$MYSQL_HOST
ENV userhost=$BLUECHERRY_USERHOST
ENV user=$BLUECHERRY_DB_USER
ENV password=$BLUECHERRY_DB_PASSWORD
ENV BLUECHERRY_GROUP_ID=${BLUECHERRY_GROUP_ID:-1001}
ENV BLUECHERRY_USER_ID=${BLUECHERRY_USER_ID:-1001}

#######################################################
# build the application from github
#######################################################

FROM scratch AS build

WORKDIR /root
RUN \
    apt-get update && \
    apt-get install -y git sudo && \
    git clone https://github.com/bluecherrydvr/bluecherry-apps.git && \
    cd bluecherry-apps && \
    scripts/build_pkg_native.sh

#######################################################
# create a container to host the bluecherry service
#######################################################

FROM scratch AS bluecherry
MAINTAINER raymond.bennett@gmail.com
WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build /root/bluecherry-apps/releases/*.deb /root/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY etc/bluecherry.con[f] /etc/bluecherry.conf

RUN /usr/sbin/groupadd -r -f -g $BLUECHERRY_GROUP_ID bluecherry && \
    useradd -c "Bluecherry DVR" -d /var/lib/bluecherry -g bluecherry -G audio,video -r -m bluecherry -u $BLUECHERRY_USER_ID && \
    { \
        echo "[client]";                        \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysql]";                         \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysqldump]";                     \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysqldiff]";                     \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
    } > /root/.my.cnf                           && \
    apt-get update                              && \
    apt-get install -y supervisor wget gnupg rsyslog mysql-client-5.7                   \
        ssl-cert curl sysstat mkvtoolnix php-mail php-mail-mime                         \
        php-net-smtp sqlite3 nmap apache2 v4l-utils vainfo php-sqlite3                  \
        libapache2-mod-php php-gd php-curl php-mysql libmysqlclient20 libopencv-core3.2 \
        libopencv-imgproc3.2                                                            && \
    { \
        echo bluecherry bluecherry/mysql_admin_login password $MYSQL_ADMIN_LOGIN;       \
        echo bluecherry bluecherry/mysql_admin_password password $MYSQL_ADMIN_PASSWORD; \
        echo bluecherry bluecherry/db_host string $host;                                \
        echo bluecherry bluecherry/db_userhost string $userhost;                        \
        echo bluecherry bluecherry/db_name string $dbname;                              \
        echo bluecherry bluecherry/db_user string $user;                                \
        echo bluecherry bluecherry/db_password password $password;                      \
    } | debconf-set-selections  && \
    dpkg -i bluecherry_*.deb    && \
    apt-get autoremove -y

CMD ["/usr/bin/supervisord"]
