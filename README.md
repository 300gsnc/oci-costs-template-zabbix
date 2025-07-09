# oci-costs-template-zabbix

  Integração de Custos da OCI com Zabbix – Template de Descoberta

1. Criar Template no Zabbix

Acesse o menu Data Collection > Templates

Crie um novo template (ex: Template OCI Costs)

Dentro do template, crie uma Discovery Rule com os seguintes parâmetros:

  Name: OCI Services Discovery
  Type: Zabbix Agent
  Key: oci.discovery

2. Adicionar Item Prototypes
Na Discovery Rule criada, adicione 3 Item Prototypes para coletar os custos por período:

Item Prototype: Custos Diários

  Name: OCI Cost 1d – {#SERVICE}
  Type: Zabbix trapper
  Key: oci.costs[{#SERVICE}.1d]

  Name: OCI Cost 7d – {#SERVICE}
  Type: Zabbix trapper
  Key: oci.costs[{#SERVICE}.7d]

  Name: OCI Cost 30d – {#SERVICE}
  Type: Zabbix trapper
  Key: oci.costs[{#SERVICE}.30d]

3. Associar Template ao Host
Associe o template ao host que irá executar o script costs_zabbix.sh.

Esse host será responsável por coletar os dados e enviá-los ao Zabbix via zabbix_sender.

4. Preparar o Host Monitorado
No host que está executando o zabbix-agent:

Baixe e coloque o script costs_zabbix.sh em:

/etc/zabbix/scripts/

Edite o script e:

- Configure o OCID do Tenancy
- Ajuste o IP do Zabbix Server
- Defina o nome do Host Zabbix

No arquivo /etc/zabbix/zabbix_agentd.conf, adicione a seguinte linha:

  UserParameter=oci.discovery,/etc/zabbix/scripts/costs_zabbix.sh --discover

5. Reiniciar o Agente Zabbix

  systemctl restart zabbix-agent

6. Agendar Execução Diária via Crontab

Edite o crontab do root (crontab -e) e adicione as linhas:

  5  12 * * * root /etc/zabbix/scripts/costs_zabbix.sh 1d
  10 12 * * * root /etc/zabbix/scripts/costs_zabbix.sh 7d
  15 12 * * * root /etc/zabbix/scripts/costs_zabbix.sh 30d

📝 Observações Importantes

- O script utiliza Instance Principal para autenticação na OCI.
- Após associar o template ao host, force a execução da discovery para que os itens sejam criados.
- Certifique-se de que o host no Zabbix tenha o mesmo nome configurado no script.

