FROM dxflrs/garage:v2.0.0

# Cria o diretório padrão de configuração interna
RUN mkdir -p /etc

# Copia o script de inicialização para dentro da imagem
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Portas padrão do Garage (S3 API, RPC, S3 Web)
EXPOSE 3900 3901 3902

ENTRYPOINT ["/bin/sh", "/start.sh"]