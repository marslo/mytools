<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Environment](#environment)
  - [cfssl & cfssljson](#cfssl--cfssljson)
  - [etcd](#etcd)
- [Certificate](#certificate)
  - [CSR and CA](#csr-and-ca)
  - [Client](#client)
  - [Service](#service)
  - [Peer](#peer)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Environment

### cfssl & cfssljson

    curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    chmod +x /usr/local/bin/cfssl*

### etcd

    $ etcdVer='v3.3.15'
    $ curl -sSL \
           https://github.com/coreos/etcd/releases/download/${etcdVer}/etcd-${etcdVer}-linux-amd64.tar.gz \
           | sudo tar -xzv --strip-components=1 -C /usr/local/bin/

## Certificate

    $ sslPath=/etc/etcd/ssl
    $ mkdir -p "${sslPath}"

### CSR and CA

    $ cd "${sslPath}"
    $ sudo /usr/local/bin/cfssl gencert -initca ca-csr.json | sudo /usr/local/bin/cfssljson -bare ca -

### Client

    $ sudo /usr/local/bin/cfssl gencert \
           -ca=ca.pem \
           -ca-key=ca-key.pem \
           -config=ca-config.json \
           -profile=client \
           client.json \
           | sudo /usr/local/bin/cfssljson -bare client

### Service

    $ sudo /usr/local/bin/cfssl gencert \
            -ca=ca.pem \
            -ca-key=ca-key.pem \
            -config=ca-config.json \
            -profile=server \
            config.json \
            | sudo /usr/local/bin/cfssljson -bare server
### Peer

    $ sudo /usr/local/bin/cfssl gencert \
            -ca=ca.pem \
            -ca-key=ca-key.pem \
            -config=ca-config.json \
            -profile=peer \
            config.json \
            | sudo /usr/local/bin/cfssljson -bare peer
