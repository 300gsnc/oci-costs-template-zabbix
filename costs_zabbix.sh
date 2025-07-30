#!/bin/bash
#
# costs_zabbix.sh – coleta custos OCI e envia ao Zabbix;
#                      ou, em modo --discover, retorna JSON de LLD.
#
# Uso:
#   ./costs_zabbix.sh --discover        # retorna JSON de descoberta
#   ./costs_zabbix.sh 1d|7d|30d         # coleta custos e envia valores

OCI_REGION="xxx"      # região do tenancy
TENANT_ID="xxx"      # ocid do tenancy
ZABBIX_SERVER="xxx" # ip do zabbix server
ZABBIX_HOST="xxx" # hostname do zabbix server

# --------- MODO DISCOVER (LLD) ---------
if [[ "$1" == "--discover" ]]; then
  # use um período amplo (ex.: últimos 30 dias) só para extrair nomes de serviço
  SD=$(date -u -d "30 days ago" +"%Y-%m-%dT00:00:00Z")
  ED=$(date -u                +"%Y-%m-%dT00:00:00Z")

  TMP=$(mktemp)
  cat >"$TMP" <<EOF
{
  "tenantId":"$TENANT_ID",
  "timeUsageStarted":"$SD",
  "timeUsageEnded":"$ED",
  "granularity":"DAILY",
  "queryType":"COST",
  "groupBy":["service"],
  "compartmentDepth":2,
  "filter":null
}
EOF

  RESP=$(sudo oci raw-request \
    --http-method POST \
    --target-uri "https://usageapi.${OCI_REGION}.oci.oraclecloud.com/20200107/usage" \
    --request-body file://"$TMP" \
    --auth instance_principal \
    --output json)

  rm -f "$TMP"

echo "$RESP" \
  | jq -r '
     (.data.items // [])
     | map(.service | gsub(" "; "_"))
     | unique
     | {data: map({"{#SERVICE}": .})}
    '
exit 0
fi

# --------- MODO ENVIO DE VALORES ---------
PERIOD="${1:-1d}"   # 1d, 7d ou 30d

# calcula intervalos UTC
case "$PERIOD" in
  1d)
    SD=$(date -u -d "yesterday" +"%Y-%m-%dT00:00:00Z")
    ED=$(date -u              +"%Y-%m-%dT00:00:00Z")
    ;;
  7d|30d)
    DAYS=${PERIOD%d}
    SD=$(date -u -d "$DAYS days ago" +"%Y-%m-%dT00:00:00Z")
    ED=$(date -u                           +"%Y-%m-%dT00:00:00Z")
    ;;
  *)
    echo "Uso: $0 [--discover|1d|7d|30d]" >&2; exit 1
    ;;
esac

# monta JSON temporário
JSON_FILE=$(mktemp)
cat >"$JSON_FILE" <<EOF
{
  "tenantId":"$TENANT_ID",
  "timeUsageStarted":"$SD",
  "timeUsageEnded":"$ED",
  "granularity":"DAILY",
  "queryType":"COST",
  "groupBy":["service"],
  "compartmentDepth":2,
  "filter":null
}
EOF

# chama OCI Usage API
RESP=$(sudo oci raw-request \
  --http-method POST \
  --target-uri "https://usageapi.${OCI_REGION}.oci.oraclecloud.com/20200107/usage" \
  --request-body file://"$JSON_FILE" \
  --auth instance_principal \
  --output json)

rm -f "$JSON_FILE"
[ -z "$RESP" ] && { echo "Erro: sem resposta OCI CLI" >&2; exit 2; }

BATCH=$(mktemp)
echo "$RESP" \
  | jq -r '
      (.data.items // [])
      | group_by(.service)[]
      | "\([.[0].service, (map(.computedAmount //0)|add)] | @tsv)"
    ' \
  | while IFS=$'\t' read -r service total; do
      service_key=$(echo "$service" | tr ' ' '_')
      key="oci.costs[${service_key}.${PERIOD}]"
	printf "%s\t%s\t%.2f\n" "$ZABBIX_HOST" "$key" "$total"
    done > "$BATCH"

# envia ao Zabbix
zabbix_sender -z "$ZABBIX_SERVER" -i "$BATCH" -vv
rm -f "$BATCH"
