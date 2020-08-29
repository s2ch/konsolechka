FROM huggingface/transformers-pytorch-cpu

RUN pip install awscli tendo youtokentome regex fastapi langdetect uvicorn && \
    aws s3 sync --no-sign-request s3://models.dobro.ai/gpt2/ru/pelevin/m_checkpoint-3365357/ /pelevin && \
    useradd -d /dopolnyator -M -s /bin/bash dopolnyator && \
    chown -R dopolnyator:dopolnyator /pelevin && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::CompressionTypes::Order::=gz install -y locales && \
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=ru_RU.UTF-8 && \
    ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    echo Europe/Moscow > /etc/timezone
    
WORKDIR /dopolnyator

COPY . /dopolnyator

RUN chown -R dopolnyator:dopolnyator /dopolnyator

ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

CMD ["uvicorn", "rest:app", "--reload", "--host", "0.0.0.0"]
