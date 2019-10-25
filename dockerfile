FROM alpine:3.10

#install packages
RUN apk --update add runit tini ca-certificates && \
    #get oauth-proxy from rep
    wget https://github.com/pusher/oauth2_proxy/releases/download/v4.0.0/oauth2_proxy-v4.0.0.linux-amd64.go1.12.1.tar.gz -O - | tar -xz --strip=1 -C /usr/local/bin && \
    #create oauth config folder
    apk add --no-cache shadow && \
    echo "**** create abc user and make our folders ****" && \
    useradd -u 911 -U -d /config abc && \
    usermod -G users abc && \
    mkdir -p \
	/config \
    /etc/service && \
    #copy profile file to user HOME dir for PATH
    echo '\
        . /etc/profile ; \
    ' >> /config/.profile

COPY root /

ENTRYPOINT ["tini", "--"]
CMD ["sh","-c","run-parts /opt && chpst -uabc runsvdir /etc/service"]
