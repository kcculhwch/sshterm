FROM debian as compiler
RUN apt update
RUN apt install git autoconf musl gcc musl-tools make wget bzip2 -y
RUN cd / && git clone https://github.com/mkj/dropbear.git
COPY localoptions.h /dropbear
RUN cd /dropbear && autoconf 
RUN cd /dropbear && autoheader 
RUN cd /dropbear && CC=musl-gcc ./configure --enable-static --disable-zlib
RUN cd /dropbear && make PROGRAMS="dbclient dropbearkey dropbearconvert"
RUN cd /dropbear && chmod +x dbclient
RUN cd / && wget https://busybox.net/downloads/busybox-1.29.3.tar.bz2
RUN cd / && tar jxvf busybox-1.29.3.tar.bz2
COPY bbox /busybox-1.29.3/.config
RUN cd /busybox-1.29.3 && make
RUN mkdir /busybox-1.29.3/sysbin && cd /busybox-1.29.3 && make CONFIG_PREFIX=./sysbin install
RUN sed -i  's/\/root/\/home\/cloud_user/' /etc/passwd

run addgroup cloud_user
run adduser --system --ingroup cloud_user cloud_user --disabled-password --disabled-login


FROM scratch
COPY --from=compiler /busybox-1.29.3/sysbin /
COPY --from=compiler /dropbear/dbclient /bin/ssh
COPY --from=compiler /dropbear/dropbearconvert /bin/convert
COPY --from=compiler /etc/passwd /etc/passwd
COPY --from=compiler /etc/shadow /etc/shadow
COPY --from=compiler /etc/group /etc/group

RUN mkdir /home
RUN mkdir /home/cloud_user


RUN mkdir /root
RUN echo "cat /etc/motd && ssh -h && alias add_key='vi /home/cloud_user/inputkey && convert opensssh dropbear /home/cloud_user/inputkey /home/cloud_user/.ssh/id_dropbear'" > /etc/profile
RUN mkdir /home/cloud_user/.ssh
RUN chmod go-rwx /home/cloud_user/.ssh
COPY inputkey /home/cloud_user/inputkey
COPY motd /etc/motd

RUN chown 101:1000 -R /home/cloud_user
CMD ["/bin/bash", "-l"]
