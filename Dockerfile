FROM ruby:2.4.1

RUN gem install bundler

RUN useradd -d /konsolechka -M -s /bin/bash konsolechka

WORKDIR /konsolechka

COPY . /konsolechka

RUN chown -R konsolechka:konsolechka /konsolechka
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=ru_RU.UTF-8


ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

RUN bundle

USER konsolechka

CMD ["ruby", "konsolechka.rb"]