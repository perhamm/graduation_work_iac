Перед запуском нужно установить раннер в облаке, следоватьльно, первый запуск необходимо провести с локального компьютера.

Преполагается что gcloud, терраформ и kubectl установлен на этом самом локальном компьютере...

Удалить все старые auth - 

```gcloud auth revoke --all```

В консоли облака - создать новый проект - s015937 

У него будет уникальный id - например, s015937-335713

Зайти в iam-admin/serviceaccounts - сделать новый сервис аккаунт, назвать его terrafrom, дать роль owner и создать для него ключ JSON.

Этот ключ кинуть в корень скаченного репо под именем terraform.json

```
gcloud config set project s015937-335713
gcloud auth activate-service-account --key-file=terraform.json
gcloud services enable compute.googleapis.com  container.googleapis.com  sql-component.googleapis.com sqladmin.googleapis.com  servicenetworking.googleapis.com cloudresourcemanager.googleapis.com dns.googleapis.com
gcloud config set compute/zone europe-west3-a
gcloud config set compute/region europe-west3

```

Первое применение терраформа - с локального компа.

Сначала создать баскет в Cloud Storage с именем s015937-terraform-state

Взять токен из раздела настроек раннеров, отключить шаренные раннеры.

```
terraform init
terraform plan -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713" -var="sql_pass=password"
terraform apply -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713" -var="sql_pass=password"
```

Для доступа по ssh к гитлаб-раннеру, если он нужен по каким-либо причинам, проще всего провалиться в него через ```gcloud compute ssh  gitlab-runner```

Вносим ```cat terraform.json  | base64 -w0``` в переменную $SERVICEACCOUNT проекта graduation_work_iac в разделе CI/CD настроек. Тудаже вносим PROJECTID, например, s015937-335713, RUNNER_TOKEN и пароль юзера postgres SQL_PASS. На этом этапе, если появился раннер в настройках - пайпланы должны заработать.

Включаем наш раннер в проекте graduation_work ( enable for this project)

Делаем экспорт kubectl config

```gcloud container clusters get-credentials gke-prod-cluster```

Узнаем точку входа

```kubectl cluster-info```

Добавляем её в K8S_API_URL в проекте graduation_work

Создаем аккаунт для входа
```
kubectl create namespace prod

kubectl create serviceaccount --namespace prod ci

cat << EOF | kubectl create --namespace prod -f -
        apiVersion: rbac.authorization.k8s.io/v1
        kind: Role
        metadata:
          name: prod-ci
        rules:
        - apiGroups: ["*"]
          resources: ["*"]
          verbs: ["*"]
EOF

kubectl create rolebinding --namespace prod --serviceaccount prod:ci --role prod-ci prod-ci-binding

kubectl get secret --namespace prod $( kubectl get serviceaccount --namespace prod ci -o jsonpath='{.secrets[].name}' ) -o jsonpath='{.data.token}' | base64 -d

```
Добавляем токен в K8S_CI_TOKEN в проекте graduation_work

Также добавляем SQL_HOST (Private IP address) и пароль юзера postgres SQL_PASS в graduation_work

Ставим в класетр ingress

```

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create ns nginx

helm install nginx ingress-nginx/ingress-nginx --namespace nginx --set rbac.create=true --set controller.publishService.enabled=true

```

Ставим cert-manager

```
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml

kubectl create namespace cert-manager

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install cert-manager \
 --namespace cert-manager \
 --version v0.12.0 \
 --set ingressShim.defaultIssuerName=letsencrypt \
 --set ingressShim.defaultIssuerKind=ClusterIssuer \
 jetstack/cert-manager


```

После создания ингресс контроллера смотрим ip лоад балансера - и заносим ip как А запись в днс своего домена.
```
kubectl get service -A
nginx          nginx-ingress-nginx-controller             LoadBalancer   10.103.250.72    34.159.44.133
```

Settings > Repository в репо приложения находим Deploy tokens и нажимаем Expand.

В поле Name вводим

k8s-pull-token

И ставим галочку рядом с read_registry.

Все остальные поля оставляем пустыми.

Нажимаем Create deploy token.

НЕ ЗАКРЫВАЕМ ОКНО БРАУЗЕРА!

Создаем image pull secret - для того, чтобы наш кластер Kubernetes мог получать образы из registry gitlab'а.

```
kubectl create secret docker-registry gitlab-registry --docker-server registry.gitlab.com --docker-email 'fyvaoldg@gmail.com' --docker-username '<первая строчка из окна создания токена в gitlab>' --docker-password '<вторая строчка из окна создания токена в gitlab>' --namespace prod
```

Также необходимо предсоздать БД для приложения - делать нужно с VM раннера, предварительно поставив psql ( БД доступна только во внутренней сети )

```
gcloud compute ssh  gitlab-runner
sudo -i
apt install postgresql-client-common postgresql-client -y

psql -v ON_ERROR_STOP=1 -h <ip bd> --username postgres -W <<-EOSQL
    CREATE DATABASE yelbdatabase;
    \connect yelbdatabase;
	CREATE TABLE restaurants (
    	name        char(30),
    	count       integer,
    	PRIMARY KEY (name)
	);
	INSERT INTO restaurants (name, count) VALUES ('outback', 0);
	INSERT INTO restaurants (name, count) VALUES ('bucadibeppo', 0);
	INSERT INTO restaurants (name, count) VALUES ('chipotle', 0);
	INSERT INTO restaurants (name, count) VALUES ('ihop', 0);
EOSQL
```
Итого, должны быть следущие переменные:

graduation_work:

K8S_API_URL

K8S_CI_TOKEN

SQL_HOST

SQL_PASS


graduation_work_iac: 

PROJECTID

RUNNER_TOKEN

SERVICEACCOUNT

SQL_PASS

Проверяем, сделав пробный запуск (id image берем после первого успешного запуска пайплана graduation_work)

```
helm upgrade --install graduation_work .helm 
        --set image_yelb_app=registry.gitlab.com/perhamm/graduation_work 
        --set imageTag_yelb_app=main.433761190.yyelb-appserver 
        --set image_yelb_ui=registry.gitlab.com/perhamm/graduation_work 
        --set imageTag_yelb_ui=main.433761190.yelb-ui 
        --set sql_host 10.206.64.3
        --set sql_password blablabla
        --wait 
        --timeout 300s 
        --atomic 
        --debug 
        --namespace prod
```

Все удалить - terraform destroy и удалить раннер из списка раннеров. Иногда подзалипает удаление SQL - удаляем из консоли, затем, например
```
terraform state list
terraform state rm module.cloudsql.google_sql_user.user
terraform destroy
```
 Чтобы совсем окончательно все удадить - удалить баскет, и затем - отключить проект.
