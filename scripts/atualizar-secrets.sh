#!/usr/bin/env bash
# Atualiza de uma vez os secrets da AWS no GitHub a partir da credencial
# do lab do Academy. Rode logo depois de abrir o lab.
#
# Precisa do gh CLI autenticado:  https://cli.github.com
set -euo pipefail

REPO="${REPO:-JRRibeeiro/TechChalegger3}"
CRED="${CRED:-$HOME/.aws/credentials}"

command -v gh >/dev/null || { echo "instale o gh CLI primeiro"; exit 1; }
[ -f "$CRED" ] || { echo "nao achei $CRED — cole a credencial do lab nele"; exit 1; }

pega () { grep -E "^\s*$1" "$CRED" | head -1 | cut -d= -f2- | tr -d ' "'; }

KEY=$(pega aws_access_key_id)
SEC=$(pega aws_secret_access_key)
TOK=$(pega aws_session_token)

[ -n "$KEY" ] && [ -n "$SEC" ] && [ -n "$TOK" ] || { echo "credencial incompleta"; exit 1; }

printf '%s' "$KEY" | gh secret set AWS_ACCESS_KEY_ID     --repo "$REPO"
printf '%s' "$SEC" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO"
printf '%s' "$TOK" | gh secret set AWS_SESSION_TOKEN     --repo "$REPO"

echo "secrets atualizados em $REPO"
echo "validade tipica do lab: cerca de 4 horas"
