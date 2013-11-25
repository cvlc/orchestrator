# Test client for Orchestrator
#
# VERSION           0.0.1

FROM ubuntu
ADD https://raw.github.com/cvlc/pipework/master/pipework /usr/bin/pipework
RUN mkdir /var/run/sshd
RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main restricted universe' > /etc/apt/sources.list 
RUN echo '#!/bin/bash\nip link set lo up\n/usr/sbin/sshd -D &\n/usr/sbin/nginx -c /etc/nginx/nginx.conf' >> /usr/bin/startscript
RUN chmod +x /usr/bin/pipework /usr/bin/startscript
RUN apt-get -y update
RUN apt-get -y install nginx openssh-server
RUN mkdir -p /.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD1aKrO0XlAq7rzQiswKPt/u/UWmakzxjJnTmtHB33rnekZtweSXLhN9tokhHcEWlWfxJw+K1NVfhZeJfL7NXISvx9vojncSONfw8Y1uiX3Pn176KLN9sT3QjV5fNl31rBuTXoUtuGWomjN9lXVhyz4rEDrMEBTp2LZ0UQsg5lG8tiIZIpY5WCx0T8fmge1EjLnjzybfG37YV6+uI0PS/lAvOs5gC87bZkqECI0Nvj6p8WU3hHkOQ4lqrTGa3sEPHoqO5SnlDBkpuec2SyXnc945t4B1xxrHpLdah2vYxKL/mm2c3WxrQU7xNv4uyCC8ASFY5yYZaSKlvzcRGZbSyd user@host" >> /.ssh/authorized_keys
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i 's/#listen/listen/g' /etc/nginx/sites-enabled/default
CMD /usr/bin/startscript
