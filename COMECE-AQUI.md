# COMECE POR AQUI — Tech Challenge Fase 3

Este é o ponto de entrada. Leia esta página inteira antes de rodar
qualquer comando; ela tem duas armadilhas que custam horas se você
descobrir no meio do caminho.

---

## 1. O que instalar

Quatro ferramentas. Só a primeira tem exigência de versão.

### Terraform — precisa ser 1.10 ou superior

A versão importa: `use_lockfile` no backend S3, que o desafio pede
nominalmente, só existe a partir da 1.10.

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform version   # confirme que é >= 1.10
```

### AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscli.zip
unzip -q awscli.zip && sudo ./aws/install --update
aws --version
```

### kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Helm

O Terraform instala o ArgoCD via provider Helm, que precisa do binário
disponível na máquina.

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Docker não é necessário.** Quem constrói as imagens é o GitHub Actions.
Instale apenas se quiser testar um build local.

---

## 2. As duas armadilhas

Leia antes de começar. Sério.

### Armadilha 1 — o apply precisa ser em duas etapas

O provider Kubernetes é configurado com o endereço de um cluster que
ainda não existe no primeiro apply. O Terraform não consegue planejar um
provider cuja configuração depende de algo do mesmo apply, e falha com
erro de configuração inválida.

A solução é criar o cluster primeiro, depois o resto:

```bash
terraform apply -target=module.eks      # etapa 1: rede e cluster
terraform apply                          # etapa 2: todo o restante
```

Se você rodar `terraform apply` direto, vai falhar. Não é bug do código,
é uma limitação conhecida do Terraform.

### Armadilha 2 — sua credencial do Academy expira

O lab do AWS Academy entrega credencial temporária de poucas horas. Ela
é usada em dois lugares: no seu terminal e nos Secrets do GitHub, que o
pipeline usa para enviar imagem ao ECR.

Quando o lab reinicia, **os três valores mudam** e o pipeline para de
funcionar até você atualizar os Secrets. Use o script:

```bash
./scripts/atualizar-secrets.sh
```

Abra o lab e rode esse script logo antes de gravar o vídeo. Você ganha
uma janela inteira de trabalho.

---

## 3. Ordem de execução

Cada passo depende do anterior. Não pule.

### Passo 1 — Criar os dois repositórios no GitHub

- `TechChalegger3` — código, Terraform e workflows
- `TechChalegger3-gitops` — apenas manifestos

Deixe o de GitOps **público**. Assim o ArgoCD lê sem precisar de
credencial dentro do cluster, e é uma dor a menos no Academy.

### Passo 2 — Montar o TechChalegger3

```
TechChalegger3/
├── terraform/          ← pasta terraform/ deste pacote
├── .github/workflows/  ← pasta .github/workflows/ deste pacote
├── argocd/             ← pasta argocd/ deste pacote
├── docs/               ← pasta docs/ deste pacote
├── scripts/            ← pasta scripts/ deste pacote
└── services/           ← os 5 microsserviços vindos da Fase 2
```

Os serviços vêm do repositório antigo, renomeando a pasta:

```bash
git clone https://github.com/JRRibeeiro/TechChalegger2.git /tmp/f2
cp -r /tmp/f2/local services
rm -f services/docker-compose.yml services/README.md
```

**Importante:** o workflow espera exatamente `services/<nome>/Dockerfile`.
Se a pasta tiver outro nome, os cinco pipelines quebram no checkout.

### Passo 3 — Montar o TechChalegger3-gitops

Copie o conteúdo da pasta `gitops/` deste pacote para a raiz dele.

### Passo 4 — Bucket do state

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="bucket_name=tc3-tfstate-SEUNOME-2026"
```

O nome precisa ser único no mundo inteiro, não só na sua conta. Depois
abra `terraform/backend.tf` e troque `BUCKET_DO_BOOTSTRAP` por ele.

### Passo 5 — Conferir a versão do Kubernetes

O padrão em `variables.tf` é `1.31`. Confirme o que o Academy oferece hoje:

```bash
aws eks describe-addon-versions --query 'addons[0].addonVersions[0].compatibilities[].clusterVersion' --output text
```

Ajuste `cluster_version` se for diferente.

### Passo 6 — Validar antes de aplicar

```bash
cd terraform
terraform init
terraform validate
```

Este passo confere nome de atributo contra o schema do provider. Eu não
consegui rodá-lo no meu ambiente porque o registry estava bloqueado —
então **é aqui que um erro de digitação meu vai aparecer**, se houver.
Me mande a saída se reclamar de alguma coisa.

### Passo 7 — Aplicar

```bash
terraform apply -target=module.eks
terraform apply
```

De 25 a 30 minutos no total. RDS e ElastiCache são os mais lentos.

### Passo 8 — Conectar o kubectl

```bash
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

### Passo 9 — Componentes do cluster

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
```

### Passo 10 — Secrets do GitHub

No `TechChalegger3`, em Settings → Secrets and variables → Actions:

| Secret | De onde vem |
|---|---|
| `AWS_ACCESS_KEY_ID` | painel do lab do Academy |
| `AWS_SECRET_ACCESS_KEY` | painel do lab do Academy |
| `AWS_SESSION_TOKEN` | painel do lab do Academy |
| `ECR_REGISTRY` | `terraform output -raw ecr_registry` |
| `GITOPS_TOKEN` | token do GitHub, veja abaixo |

O `GITOPS_TOKEN` é o que permite o pipeline escrever no outro
repositório. Em github.com/settings/tokens crie um **fine-grained token**
com acesso só ao `TechChalegger3-gitops` e permissão de escrita em
Contents.

### Passo 11 — Apontar os manifestos para o seu ECR

No repositório de GitOps, troque `SEU_ECR_REGISTRY` pelo valor real nos
cinco `deployment.yaml`:

```bash
REG=$(cd ../terraform && terraform output -raw ecr_registry)
sed -i "s|SEU_ECR_REGISTRY|$REG|g" apps/*/deployment.yaml
git commit -am "aponta imagens para o ECR" && git push
```

### Passo 12 — Applications do ArgoCD

```bash
kubectl apply -f argocd/applications.yaml
kubectl get applications -n argocd
```

Senha do admin e endereço da interface:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd get svc argocd-server
```

### Passo 13 — Primeiro deploy

Faça um push em qualquer serviço e acompanhe: o pipeline roda, publica no
ECR, commita no repositório de GitOps, e o ArgoCD sincroniza sozinho.

---

## 4. Antes de gravar

Leia `docs/roteiro-video.md`. Ele tem um checklist pré-gravação, e o item
mais importante é **preparar a falha de segurança com antecedência**: a
dependência vulnerável precisa estar escolhida e testada antes, com a
CVE crítica confirmada, e o commit de correção já pronto.

---

## 5. Pendências que não estão neste pacote

- **Relatório em PDF** com nomes dos participantes, link do vídeo, resumo
  dos desafios e print da estimativa de custo. A estimativa monte na
  calculadora de preços da AWS, já que o Academy roda com crédito.
- **Vídeo gravado.**

---

## 6. Segredos vazados na Fase 2

Estes valores estão em texto plano no histórico público do
`TechChalegger2` e não podem ser reaproveitados:

- senhas dos três bancos
- `MASTER_KEY` do auth-service
- `SERVICE_API_KEY` do evaluation-service

Na Fase 3 nenhum deles existe em arquivo: todos são gerados pelo
Terraform e injetados no cluster como Secret. Se as instâncias RDS da
Fase 2 ainda estiverem de pé, derrube.
