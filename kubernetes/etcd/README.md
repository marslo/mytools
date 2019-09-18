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
