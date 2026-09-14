# Roteiro do vídeo — Tech Challenge Fase 3

Teto de 20 minutos. Os quatro itens obrigatórios do PDF estão marcados
com **[OBRIGATÓRIO]** — se algum deles não aparecer, a entrega fica
incompleta independente do resto.

---

## Antes de apertar o REC

Isso não é opcional. Metade das regravações acontece porque um destes
itens não estava pronto.

**Ambiente**
- [ ] Sessão do AWS Academy recém-aberta (você tem ~4h, grave no começo)
- [ ] `terraform apply` já concluído — **não** dá pra esperar 30 min no vídeo
- [ ] `kubectl get pods -n techchallenger` com os 5 rodando
- [ ] ArgoCD acessível: LoadBalancer no ar ou `port-forward` já ativo
- [ ] ArgoCD com os 5 Applications criados e sincronizados (estado verde)

**Falha plantada** — o item que mais dá errado ao vivo
- [ ] Dependência vulnerável já escolhida e testada, com CVE CRÍTICA conhecida
- [ ] Você já rodou o pipeline com ela uma vez e confirmou que ele quebra
- [ ] O commit de correção já está pronto, só faltando dar o push

**Telas abertas em abas separadas, na ordem de uso**
1. Editor com a pasta `terraform/`
2. Console AWS: VPC, EKS, RDS
3. GitHub → aba Actions do TechChalegger3
4. GitHub → TechChalegger3-gitops, na tela de commits
5. ArgoCD

**Gravação**
- [ ] Notificações do sistema desativadas
- [ ] Fonte do terminal ampliada (o avaliador assiste no celular às vezes)
- [ ] Nenhuma credencial visível na tela — cuidado com `~/.aws/credentials`,
      histórico do shell e a aba de Secrets do GitHub

---

## Minuto a minuto

### 0:00 – 1:00 — Abertura
Nome dos participantes. Uma frase sobre o que é o ToggleMaster.
Depois o contraste que dá sentido ao resto:

> "Na Fase 2 esse ambiente foi criado com seis scripts bash e cliques no
> console. Recriar homologação levava dias. O que eu vou mostrar agora é
> o mesmo ambiente inteiro descrito em código."

### 1:00 – 5:00 — IaC **[OBRIGATÓRIO]**
Abra a pasta `terraform/` e percorra a estrutura de módulos: network,
eks, data-stores, ecr. Não leia arquivo linha por linha — mostre a
organização e pare em três pontos:

1. `backend.tf` — o state no S3 com `use_lockfile`. Diga por que não pode
   ser local: dois devs rodando apply ao mesmo tempo corrompem o estado.
2. `modules/eks/main.tf` — a LabRole lida por data source. Explique a
   restrição do Academy: o Terraform não pode criar IAM, então reaproveita.
3. `modules/data-stores/main.tf` — `publicly_accessible = false`.
   Aqui você fala que na Fase 2 o banco estava exposto e a senha estava
   versionada, e que esta linha encerra isso.

Depois vá ao console e mostre o resultado: a VPC com as subnets, o
cluster EKS, os três RDS. O PDF aceita mostrar o resultado final em vez
do apply rodando — aproveite essa permissão.

Se tiver fôlego, rode um `terraform plan` rápido só pra mostrar
"No changes" — prova que o que está na AWS é exatamente o que está no código.

### 5:00 – 12:00 — Pipeline DevSecOps **[OBRIGATÓRIO]**
O trecho mais longo, e o mais importante.

Mostre o arquivo de workflow e nomeie os estágios em voz alta: build,
lint, SCA, SAST, build da imagem, scan da imagem, push.

Explique a diferença em uma frase, porque o avaliador vai querer ouvir:
SCA olha as bibliotecas que você importou, SAST olha o código que você
mesmo escreveu.

Agora a demonstração:
1. Faça o push com a dependência vulnerável
2. Acompanhe o pipeline **falhando** no estágio de segurança
3. Abra o log e aponte a CVE e a severidade CRÍTICA
4. Diga a frase-chave: "o pipeline não prossegue, então essa imagem nunca
   chega no ECR e nunca chega no cluster"
5. Faça o push da correção
6. Mostre passando

Se o pipeline demorar, corte na edição — mas mantenha o antes e o depois.

### 12:00 – 15:00 — Push e GitOps **[OBRIGATÓRIO]**
Com o pipeline verde, mostre a imagem chegando no ECR com a tag do
commit, não `latest`. Explique por que isso importa: com `latest` você
não sabe qual versão está rodando, e não tem como voltar atrás.

Então mude de aba para o **TechChalegger3-gitops** e mostre o commit que
o pipeline fez sozinho, alterando a tag no `deployment.yaml`.

Essa troca de aba é o momento em que a separação dos repositórios fica
visível. Fale enquanto mostra: "quem escreveu esse commit foi o pipeline,
não eu."

### 15:00 – 18:30 — ArgoCD **[OBRIGATÓRIO]**
Abra o ArgoCD com os 5 microsserviços na tela. Mostre o estado passando
de OutOfSync para Synced, e os pods sendo substituídos.

Feche o raciocínio:

> "Ninguém rodou kubectl. O cluster está assim porque o repositório diz
> que ele deve estar assim."

### 18:30 – 20:00 — Decisões e limitações
Aqui você ganha pontos sendo honesto, não perfeito:

- **Senha fora do repositório** — geradas pelo Terraform, vivem no state
  e chegam ao cluster como Secret
- **Hop limit do IMDS** — o bug da Fase 2 resolvido na origem pelo
  launch template, não mais na mão a cada nó novo
- **Credencial do CI no Academy** — é temporária e expira junto com o lab;
  numa conta real isso seria federação entre GitHub e AWS, sem secret fixo
- **NAT desligado** — decisão de custo, com a variável pronta para ligar

---

## Erros que custam nota

- Deixar o `apply` rodando na tela: queima 30 dos seus 20 minutos
- Pipeline falhando por motivo errado (erro de sintaxe em vez de CVE):
  não demonstra o controle de segurança, demonstra que o código não compila
- Mostrar ArgoCD já sincronizado sem mostrar a transição: o exigido é
  ele **detectando** a mudança
- Credencial aparecendo na tela
- Passar de 20 minutos
