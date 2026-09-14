# Post para o LinkedIn

Publicar **depois** da entrega aprovada. Antes disso o texto fala no
passado sobre coisa que ainda não foi validada.

Troque `[LINK]` pelo repositório e confira os números antes de postar.

---

## Versão principal

Na Fase 2 da pós eu migrei um sistema de feature flags para
microsserviços na AWS. Funcionou. E era insustentável.

O ambiente tinha nascido de seis scripts bash e de cliques no console.
Recriar homologação levava dias. As senhas dos bancos estavam em texto
plano dentro do repositório. E os bancos estavam com acesso público.

A Fase 3 foi desmontar isso.

O que mudou:

→ Toda a infraestrutura virou Terraform. VPC, EKS, três instâncias RDS,
Redis, DynamoDB e SQS. State remoto no S3, com lock. O ambiente que
levava dias agora sobe em torno de 30 minutos, e sempre igual.

→ Os bancos saíram da internet. Foram para subnet privada, aceitando
conexão apenas do security group dos nós do cluster.

→ As senhas saíram do código. São geradas pelo Terraform, vivem só no
state e chegam ao cluster como Secret. Nenhum repositório versiona
credencial.

→ Cada microsserviço ganhou um pipeline com análise de dependências e
análise estática de código. Vulnerabilidade crítica interrompe o
processo, e a imagem não chega ao registry.

→ O deploy deixou de ser kubectl na mão. O pipeline atualiza a tag da
imagem num repositório separado de manifestos, e o ArgoCD sincroniza
o cluster a partir dali.

O detalhe que mais me marcou foi outro.

Na Fase 2 eu tinha um bug conhecido: os pods não alcançavam o metadata
service da AWS porque o limite de saltos estava em 1. Eu corrigia na mão,
mas cada nó novo criado pelo autoscaling nascia quebrado de novo.

Em Terraform isso vira uma linha no launch template. O problema não é
corrigido — ele deixa de acontecer.

É a diferença entre operar um ambiente e descrever um ambiente. Levei
duas fases para sentir isso na prática.

Código aberto no repositório: [LINK]

#DevOps #AWS #Terraform #InfraestruturaComoCodigo #DevSecOps #GitOps
#ArgoCD #Kubernetes #EKS #CICD #CloudComputing #FIAP #PosTech

---

## Versão curta

Passei a Fase 3 da pós desmontando o que eu mesmo tinha construído na
Fase 2.

O ambiente funcionava, mas tinha nascido de scripts bash e cliques no
console. Senha de banco versionada em texto plano. Banco com acesso
público. Recriar homologação levava dias.

Reescrevi tudo em Terraform, tirei os bancos da internet, tirei as
senhas do repositório, coloquei análise de vulnerabilidade bloqueante
nos pipelines e troquei o kubectl na mão por GitOps com ArgoCD.

O que mais me marcou: um bug que eu corrigia manualmente a cada nó novo
virou uma linha no launch template. Em vez de corrigido, ele deixou de
acontecer.

Repositório: [LINK]

#DevOps #AWS #Terraform #DevSecOps #GitOps #Kubernetes #CICD #FIAP

---

## Notas de edição

**O que sustenta o post.** O contraste entre as fases. Quase ninguém
publica o que estava errado no próprio projeto anterior — isso lê como
maturidade, não como falha.

**O que não colocar.** Nada de "especialista". Nada de "revolucionário"
ou "game changer". Nenhum print com endpoint, ARN ou ID de conta.

**Se quiser levar mais longe.** O trecho do hop limit do IMDS dá um post
técnico próprio depois: sintoma, investigação e correção. Rende mais
que este, e é conteúdo que quase não existe em português.
