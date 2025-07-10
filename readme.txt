# oci-costs-template-zabbix

  Integração de Custos da OCI com Zabbix – Template de Descoberta

1.  Importe o template 'oci_costs_template_zabbix.xml' no zabbix.

2. Associar Template ao Host
Associe o template ao host que irá executar o script costs_zabbix.sh.

Esse host será responsável por coletar os dados e enviá-los ao Zabbix via zabbix_sender.

3. Preparar o Host Monitorado
No host que está executando o zabbix-agent:

Baixe e coloque o script costs_zabbix.sh em:

/etc/zabbix/scripts/

Edite o script e:

- Configure o OCID do Tenancy
- Ajuste o IP do Zabbix Server
- Defina o nome do Host Zabbix

No arquivo /etc/zabbix/zabbix_agentd.conf, adicione a seguinte linha ao final do arquivo:

  UserParameter=oci.discovery,/etc/zabbix/scripts/costs_zabbix.sh --discover

4. Reiniciar o Agente Zabbix

  systemctl restart zabbix-agent

5. Agendar Execução Diária via Crontab

Edite o crontab do root (crontab -e) e adicione as linhas:

  1  0 * * * root /etc/zabbix/scripts/costs_zabbix.sh 1d
  2 0 * * * root /etc/zabbix/scripts/costs_zabbix.sh 7d
  3 0 * * * root /etc/zabbix/scripts/costs_zabbix.sh 30d

📝 Observações Importantes

- O script utiliza Instance Principal para autenticação na OCI, configurar policy no tanancy para permitir 'cost-usage'.
- Após associar o template ao host, force a execução da discovery para que os itens sejam criados.
- Certifique-se de que o host no Zabbix tenha o mesmo nome configurado no script.
- O script coleta apenas custos por recurso.
- No template o discovery do custo por recurso e descoberto de forma automatizada. Os cálculos configurados, estão estaticos de acordo com o recurso que foi encontrado, em casos especificos algum recurso pode não ser descoberto, como es uma requisição que obtem a resposta da api da oci o calculo fica de forma estatica, então caso algum recurso descoberto naõ esteja no calculo do template atual, precisa ajustar de forma manual no zabbix direto no template para que o calculo fique correto. Vale para os items
  - Total Costs 1d
  - Total Costs 7d
  - Total Costs 30d
