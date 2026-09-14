# Nginx Ingress Controller

O ArgoCD gerencia as aplicações, mas o controller de Ingress é
infraestrutura do cluster e é instalado uma vez só:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
```

Metrics Server, necessário para os HPAs funcionarem. A versão está
fixada de propósito: a `latest` quebrou no EKS da Fase 2.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
```

Aguarde o LoadBalancer subir:

```bash
kubectl get svc -n ingress-nginx -w
```
