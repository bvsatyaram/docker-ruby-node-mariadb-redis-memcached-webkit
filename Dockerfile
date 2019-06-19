FROM ubuntu:14.04

# Basics
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*


# ruby
RUN \
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
  curl -L https://get.rvm.io | bash -s stable && \
  bash -c -l 'rvm install ruby-2.5.3' && \
  bash -c -l 'rvm use --default 2.5.3' && \
  bash -c -l 'gem install bundler --no-ri --no-rdoc'

# Install Webkit
RUN apt-get install -y g++ qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x xvfb

# Upgrade openssl
RUN \
  wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && \
  tar -zxf openssl-1.1.1a.tar.gz && \
  cd openssl-1.1.1a && \
  ./config && \
  make && \
  mv /usr/bin/openssl ~/tmp && \
  make install && \
  ln -s /usr/local/bin/openssl /usr/bin/openssl && \
  ldconfig && \
  cd .. && \
  rm -rf openssl-1.1.1a

# Install Node
RUN \
  curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh && bash nodesource_setup.sh && rm nodesource_setup.sh && \
  apt-get install -y nodejs && \
  npm i -g yarn

# Install MySQL
RUN \
  apt-get install -y libmariadbclient-dev && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0xcbcb082a1bb943db && \
  echo "deb http://mariadb.mirror.iweb.com/repo/10.3/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  echo "mysqld_safe &" > /tmp/config && \
  echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
  echo "mysql -e 'DROP USER IF EXISTS \"root\"@\"%\";'" >> /tmp/config && \
  echo "mysql -e 'CREATE USER \"root\"@\"%\";'" >> /tmp/config && \
  echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
  bash /tmp/config && \
  rm -f /tmp/config

VOLUME ["/etc/mysql", "/var/lib/mysql"]

CMD ["mysqld_safe"]

EXPOSE 3306

# Install Redis
RUN \
  cd /tmp && \
  wget http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  make && \
  make install && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /etc/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable* && \
  sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
  sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis.conf

VOLUME ["/data"]

CMD ["redis-server", "/etc/redis/redis.conf"]

EXPOSE 6379


# Install Memcached
ENV MEMCACHED_USER=nobody \
    MEMCACHED_VERSION=1.5.16

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y memcached&& \
  # memcached=${MEMCACHED_VERSION}* && \
  sed 's/^-d/# -d/' -i /etc/memcached.conf && \
  rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 11211/tcp 11211/udp
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/bin/memcached"]
