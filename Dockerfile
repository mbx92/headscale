FROM headscale/headscale:0.28.0

COPY config.yaml /etc/headscale/config.yaml
COPY acl.json /etc/headscale/acl.json

CMD ["serve"]
