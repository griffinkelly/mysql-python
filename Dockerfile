FROM docker:stable

RUN apk add --no-cache python2

RUN apk --no-cache add curl
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python2 get-pip.py

RUN pip install mysql-connector-python


# Environment variables
ENV GITHUB_TEST True

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
