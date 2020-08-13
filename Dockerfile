FROM ruby:2.6.6-stretch

RUN gem install bundler

RUN ln -s /usr/lib/apt/methods/http /usr/lib/apt/methods/https && echo "deb ftp://ftp.se.debian.org/debian/ stretch main" > /etc/apt/sources.list

RUN apt-get -o Acquire::CompressionTypes::Order::=gz update && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::CompressionTypes::Order::=gz install -y ffmpeg

RUN useradd -d /konsolechka -M -s /bin/bash konsolechka

WORKDIR /konsolechka

COPY . /konsolechka

RUN chown -R konsolechka:konsolechka /konsolechka

RUN DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::CompressionTypes::Order::=gz install -y locales

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=ru_RU.UTF-8


ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

RUN bundle

USER konsolechka

CMD ["ruby", "konsolechka.rb"]