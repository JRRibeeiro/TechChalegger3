# Infraestrutura — Tech Challenge Fase 3

Todo o ambiente da Fase 2 reescrito em Terraform. Nada aqui depende
de clique no console nem de script bash.

## Ordem de execução

O bucket que guarda o state precisa existir antes do projeto principal
rodar. Por isso são duas etapas, e a primeira roda uma única vez na vida.

### 1. Bootstrap (uma vez só)

```bash
cd bootstrap
terraform init
terraform apply -var="bucket_name=SEU-BUCKET-UNICO-AQUI"
```

O nome precisa ser único no mundo, não só na sua conta. Anote o que
saiu no output.

### 2. Apontar o backend

Em `backend.tf`, troque `BUCKET_DO_BOOTSTRAP` pelo nome que você criou.

### 3. Projeto principal

```bash
terraform init
terraform plan
terraform apply
```

RDS e ElastiCache levam por volta de 15 minutos até ficarem disponíveis.
O EKS leva mais uns 10. O apply completo fica na casa dos 25 a 30 minutos.

### 4. Conectar o kubectl

O comando pronto sai no output `kubeconfig_command`.

## Decisões que valem explicar no relatório

**Banco em subnet privada.** Na Fase 2 os três RDS subiram com
`--publicly-accessible`, expostos na internet. Aqui eles vivem em subnet
privada e só aceitam conexão vinda do security group dos nós do cluster.

**Senha fora do código.** As senhas são geradas pelo `random_password`,
ficam só no state remoto e são injetadas no cluster como Secret pelo
próprio Terraform. Nenhum arquivo versionado carrega credencial — nem
neste repositório, nem no de GitOps.

**Hop limit fixado no launch template.** A Fase 2 travou porque os pods
não alcançavam o metadata service: o limite de saltos era 1. A correção
manual funcionava, mas cada nó novo do autoscaling nascia quebrado de
novo. O launch template com `http_put_response_hop_limit = 2` resolve
isso na origem — todo nó já nasce correto.

**LabRole em vez de role própria.** O AWS Academy não deixa o Terraform
criar role nem policy de IAM. O módulo EKS lê a LabRole existente via
data source e associa no cluster e no node group. Numa conta pessoal,
esse é o ponto onde entrariam os recursos `aws_iam_role`.

**NAT desligado por padrão.** NAT Gateway cobra por hora e o crédito do
Academy é curto. Com `enable_nat_gateway = false`, os nós ficam em subnet
pública (precisam de saída para puxar imagem do ECR) e apenas os bancos
ficam privados. Ligando a flag, os nós migram para a subnet privada
sozinhos — a variável já controla os dois lados.

## Estrutura

```
terraform/
├── bootstrap/        bucket S3 do state (roda uma vez)
├── modules/
│   ├── network/      VPC, subnets, IGW, route tables, NAT opcional
│   ├── eks/          cluster, node group, launch template, addons
│   ├── data-stores/  3 RDS, Redis, DynamoDB, SQS e os security groups
│   └── ecr/          5 repositórios com scan on push
├── main.tf           amarra os módulos e cria o Secret no cluster
├── variables.tf
├── outputs.tf
└── backend.tf        state remoto no S3 com use_lockfile
```
