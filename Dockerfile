FROM dxflrs/garage:v2.0.0

# Copia um arquivo de configuração básico para dentro do container
RUN mkdir -p /etc
RUN echo '[metadata_dir]\n\
metadata_dir = "/var/lib/garage/meta"\n\
\n\
[data_dir]\n\
data_dir = "/var/lib/garage/data"\n\
\n\
[rpc_secret]\n\
rpc_secret = "$GARAGE_RPC_SECRET"\n\
\n\
[rpc_bind_addr]\n\
rpc_bind_addr = "0.0.0.0:3901"\n\
\n\
[s3_api]\n\
api_bind_addr = "0.0.0.0:3900"\n\
\n\
[s3_web]\n\
api_bind_addr = "0.0.0.0:3902"' > /etc/garage.toml

# Executa o comando direto na sintaxe correta
CMD ["/garage", "server"]