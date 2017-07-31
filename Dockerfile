FROM tifayuki/java:8 

MAINTAINER Aissam BENNANI 
# add some OS tools 
RUN apt-get update && \
	apt-get install -y unzip wget curl && \
	apt-get clean && \
	apt-get vim && \
	rm -rf /var/lib/apt/lists/*
# set the timezone to London 
RUN echo Europe/London > /etc/timezone && \
	dpkg-reconfigure --frontend noninteractive tzdata
# this will add AND UNPACK the kafka bundle... 
ADD kafka_2.11-0.10.0.0.tgz /opt
ENV KAFKA_HOME /opt/kafka_2.11-0.10.0.0 
ADD startup_new.sh /startup_new.sh
CHMOD +x /startup_new.sh
CMD ["/startup_new.sh"]