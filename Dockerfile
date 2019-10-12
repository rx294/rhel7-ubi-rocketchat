FROM registry.access.redhat.com/ubi7/nodejs-8

ENV RC_VERSION 2.0.0

MAINTAINER rx294@nyu.edu

LABEL name="Rocket.Chat" \
      vendor="Rocket.Chat" \
      version="${RC_VERSION}" \
      release="1" \
      url="https://rocket.chat" \
      summary="The Ultimate Open Source Web Chat Platform" \
      description="The Ultimate Open Source Web Chat Platform" \
      run="docker run -d --name ${NAME} ${IMAGE}"

USER 0

ENV PATH /opt/rh/rh-nodejs8/root/usr/bin:/opt/app-root/src/node_modules/.bin/:/opt/app-root/src/.npm-global/bin/:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN groupadd -r rocketchat \
&&  useradd -r -g rocketchat rocketchat \
&&  mkdir -p /opt/app-root/src/uploads \
&&  chown rocketchat.rocketchat /opt/app-root/src/uploads

VOLUME /opt/app-root/src/uploads
WORKDIR /opt/app-root/src/bundle

RUN set -x \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0E163286C20D07B9787EBE9FD7F9D0414FD08104 \
 && curl -SLf "https://releases.rocket.chat/${RC_VERSION}/download" -o rocket.chat.tgz \
 && curl -SLf "https://releases.rocket.chat/${RC_VERSION}/asc" -o rocket.chat.tgz.asc \
 && gpg --verify rocket.chat.tgz.asc \
 && tar -zxf rocket.chat.tgz -C /opt/app-root/src/ \
 && rm rocket.chat.tgz rocket.chat.tgz.asc \
 && cd /opt/app-root/src/bundle/programs/server \
 && npm install \
 && npm cache clear --force \
 && chown -R rocketchat:rocketchat /opt/app-root/src/bundle

# Hack needed to force use of bundled library instead of system level outdated library
ENV LD_PRELOAD=/opt/app-root/src/bundle/programs/server/npm/node_modules/sharp/vendor/lib/libz.so

USER rocketchat

ENV DEPLOY_METHOD=docker-redhat \
    NODE_ENV=production \
    MONGO_URL=mongodb://mongo:27017/rocketchat \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000

EXPOSE 3000

CMD ["node", "main.js"]
