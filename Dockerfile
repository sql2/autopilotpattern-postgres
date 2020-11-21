FROM postgres:13.1-alpine

RUN apk add --update bash curl nodejs

# Install Consul
# Releases at https://releases.hashicorp.com/consul
RUN set -ex \
    && export CONSUL_VERSION=1.8.6 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    # Create empty directories for Consul config and data \
    && mkdir -p /etc/consul \
    && mkdir -p /var/lib/consul \
    && mkdir /config

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN set -ex \
    && export CONSUL_TEMPLATE_VERSION=0.25.1 \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Add Containerpilot and set its configuration
COPY etc/containerpilot.json5 /etc
ENV CONTAINERPILOT /etc/containerpilot.json5
ENV CONTAINERPILOT_VERSION 3.8.0

RUN export archive=containerpilot-${CONTAINERPILOT_VERSION}.tar.gz \
    && curl -Lso /tmp/${archive} \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/${archive}" \
    && tar zxf /tmp/${archive} -C /usr/local/bin \
    && rm /tmp/${archive}

# Add Postgres templates
COPY etc/pg_hba.conf /etc
COPY etc/postgresql.conf.ctmpl /etc
COPY etc/recovery.conf.ctmpl /etc

# Set up Node.js app
COPY bin /bin
RUN cd /bin && npm install && npm run lint

ENTRYPOINT []
CMD ["/usr/local/bin/containerpilot"]
