oci-costs-template-zabbix

Integração de Custos da OCI com o Zabbix – Template de Descoberta

1. Importar o Template

Importe o arquivo 'zbx_export_templates.yaml' na interface do Zabbix.

2. Associar o Template ao Host

Associe o template ao host que executará o script costs_zabbix.sh.

Esse host será responsável por coletar os dados de custo e enviá-los ao Zabbix via zabbix_sender.

3. Preparar o Host Monitorado

No host onde o Zabbix Agent está em execução:

Baixe e coloque o script costs_zabbix.sh no diretório:

  /etc/zabbix/scripts/

Edite o script e configure:

  - O OCID do Tenancy
  - O IP do Zabbix Server
  - O nome do host conforme cadastrado no Zabbix

No arquivo /etc/zabbix/zabbix_agentd.conf, adicione ao final:

  UserParameter=oci.discovery,/etc/zabbix/scripts/costs_zabbix.sh --discover

4. Reiniciar o Zabbix Agent
Execute:

  systemctl restart zabbix-agent

5. Agendar Execução Diária via Crontab
Edite o crontab do root com:

  crontab -e

  1  12 * * * /etc/zabbix/scripts/costs_zabbix.sh 1d
  2  12 * * * /etc/zabbix/scripts/costs_zabbix.sh 7d
  3  12 * * * /etc/zabbix/scripts/costs_zabbix.sh 30d

📝 Observações
  -  Valide se o usuario possui permissão para executar o script 'sudo -u zabbix /etc/zabbix/scripts/costs_oci.sh --discover'.
  -  O script utiliza Instance Principal para autenticação na OCI. É necessário configurar a policy no tenancy para permitir o uso do serviço 'usage-report'.
  - Após associar o template ao host, force a execução da discovery para que os itens sejam criados automaticamente.
  - Certifique-se de que o nome do host no Zabbix seja exatamente o mesmo definido no script.
  - O script coleta apenas custos por serviço.
  - A descoberta dos serviços é feita automaticamente via script. No entanto, os cálculos de custos totais (1d, 7d, 30d) são estáticos com base nos recursos descobertos na primeira execução. Caso novos serviços sejam identificados no futuro, será necessário ajustar manualmente os itens de cálculo no template, como por exemplo:
  Total Costs 1d
  Total Costs 7d
  Total Costs 30d
  - Configuração e 'time period' utilizada nos gráficos:
  #1D
  From: now-7d
  To: now

  #30D
  From: now-30d
  To: now
  - Ajustar o item budget de acordo com seu budget atual.
  - Incluído conversão 'estática' do valor estimado para dólar.

