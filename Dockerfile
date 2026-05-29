FROM dxflrs/garage:v2.3.0 AS garage

FROM alpine:3.19

COPY --from=garage /garage /garage

RUN mkdir -p /etc /var/lib/garage/meta /var/lib/garage/data

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3900 3901 3902

ENTRYPOINT ["/bin/sh", "/start.sh"]
