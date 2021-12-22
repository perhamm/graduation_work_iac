## Описание проекта

Проект состоит из двух репозиториев https://gitlab.com/perhamm/graduation_work и https://gitlab.com/perhamm/graduation_work_iac/

В первом располагается приложение и в нем содержаться следующие файлы и папки:

* Папки yelb-appserver, yelb-db и yelb-ui - папки с изначальным приложением, форкнутые из репо задания. В приложения внесены изменения, особенно в  yelb-appserver - для поддержки установки в GCP (добавлены переменные для переопределения названий хостов баз данных и изменены докерфайлы)
* docker-compose.yml - создан для тестирования корректности запуска приложений после сборки
* Папка test - содержит тест для docker-compose.yml (просто дергает страничку приложения и читает код ответа)
* Папка deployments - не несет никакой роли, форкнута из изначального приложения
* .helm-minikube - позволяет запустить приложение в миникубе
* .helm_redis_and_cloudsql_ha - helm чарт для запуска HA редиса и HA cloudsql - попробовал что работает, но слишком много уходит денег (нужны допольнительные ресурсы для самого кубера - и нод 3 штуки, и подов для редиса получается очень много)
* .helm - позволяет запустить приложение с 1 подом редиса с персистентостью, 1 cloud sql прокси и по паре бекенд - фронтенд - при смерти редиса или sql прокси - они пересоздаются кубером автоматом, в течении 30 сек

Во втором располагается iac + всё описание проекта и в нем содержаться следующие файлы и папки:

* backend - модуль терраформа для настройки сети
* gke - модуль терраформа для настройки кластера 
* vds - модуль терраформа для настройки виртуальной машины под раннер
* cloudsql - модуль терраформа для настройки cloud sql

В gke - для оптимизации затрат используется только одна нода kubernetes (за каждую дополнительную ноды начисляется очень значительное количество денег в час + цена самой виртуалки под ноду) - но, если есть необходимость, можно просто увеличить количество нод и всё
cloudsql - запускается без HA (за HA идет значительна доплата) - но, если есть необходимость, включить HA можно раскомментировав строчки про реплику
vds - просто виртуалка под раннер, раннер ставится и регистрируется автоматически через provision

Итого получается следущая схема работы приложения:

![https://app.diagrams.net/#G1wjkWXmV4_YDXgfPPr4mmVDzlUWYRkjDw](image/Diagram.jpg)


## Описание установки

### Создание проекта в GCP
Перед запуском нужно установить раннер в облаке, следоватьльно, первый запуск необходимо провести с локального компьютера.<br/>
Преполагается что gcloud, терраформ и kubectl установлен на этом самом локальном компьютере...<br/><br/>
~~Просто заметка для себя - удалить все старые auth для чистого использования консольной gcloud можно так:~~<br/>
~~```gcloud auth revoke --all```~~<br/><br/>
В консоли облака - создать новый проект - s015937 <br/>
У него будет уникальный id - например, s015937-335713<br/>
Зайти в iam-admin/serviceaccounts - сделать новый сервис аккаунт, назвать его terrafrom, дать роль owner и создать для него ключ JSON.<br/>
Этот ключ кинуть в корень скаченного репо graduation_work_iac под именем terraform.json<br/>
```
gcloud config set project s015937-335713
gcloud auth activate-service-account --key-file=terraform.json
gcloud services enable compute.googleapis.com  container.googleapis.com  sql-component.googleapis.com sqladmin.googleapis.com  servicenetworking.googleapis.com cloudresourcemanager.googleapis.com dns.googleapis.com
gcloud config set compute/zone europe-west3-a
gcloud config set compute/region europe-west3
```
Создать баскет в Cloud Storage с именем s015937-terraform-state<br/>
### Первое применение терраформа
Первое применение терраформа - с локального компа.<br/>
Взять токен из раздела настроек раннеров, отключить шаренные раннеры, придумать сложный пароль для постгреса.<br/>
```
terraform init
terraform plan -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713" -var="sql_pass=password"
terraform apply -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713" -var="sql_pass=password"
```
### Настройки CI обоих репозиториев
Для доступа по ssh к гитлаб-раннеру, если он нужен по каким-либо причинам, проще всего провалиться в него через <br/>
```gcloud compute ssh  gitlab-runner```<br/>
Вносим ```cat terraform.json  | base64 -w0``` в переменную **SERVICEACCOUNT** проекта graduation_work_iac в разделе CI/CD настроек. <br/>Тудаже вносим **PROJECTID**, например, s015937-335713, **RUNNER_TOKEN** и пароль юзера postgres **SQL_PASS**. <br/>На этом этапе, если появился раннер в настройках - пайпланы должны заработать.<br/>
Включаем наш раннер в проекте graduation_work ( enable for this project)<br/>
Делаем экспорт kubectl config<br/>
```gcloud container clusters get-credentials gke-prod-cluster```<br/>
Узнаем точку входа<br/>
```kubectl cluster-info```<br/>
Добавляем её в **K8S_API_URL** в проекте graduation_work<br/>
### Настройки кластера для работы пайплайнов и приложения
Ставим в класетр ingress<br/>
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create ns nginx
helm install nginx ingress-nginx/ingress-nginx --namespace nginx --set rbac.create=true --set controller.publishService.enabled=true

```
Ставим cert-manager<br/>
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
После создания ингресс контроллера смотрим ip лоад балансера - и заносим ip как А запись в днс своего домена.<br/>
```
kubectl get service -A
nginx          nginx-ingress-nginx-controller             LoadBalancer   10.103.250.72    34.159.44.133
```
Создаем аккаунт для входа<br/>
```
kubectl create namespace prod
kubectl create serviceaccount --namespace prod ci
cat << EOF | kubectl create --namespace prod -f -
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRole
        metadata:
          name: prod-ci
        rules:
        - apiGroups: ["", "extensions", "apps", "batch", "events", "certmanager.k8s.io", "cert-manager.io", "monitoring.coreos.com", "networking.k8s.io"]
          resources: ["*"]
          verbs: ["*"]
EOF
kubectl create clusterrolebinding --namespace prod --serviceaccount prod:ci --clusterrole prod-ci prod-ci-binding
kubectl get secret --namespace prod $( kubectl get serviceaccount --namespace prod ci -o jsonpath='{.secrets[].name}' ) -o jsonpath='{.data.token}' | base64 -d
```
Добавляем токен в **K8S_CI_TOKEN** в проекте graduation_work<br/>
Проверить токен можно так<br/>
```
kubectl get clusterissuers --as=system:serviceaccount:prod:ci -n prod
```
Settings > Repository в репо приложения находим Deploy tokens и нажимаем Expand.<br/>
В поле Name вводим k8s-pull-token и ставим галочку рядом с read_registry.<br/>
Все остальные поля оставляем пустыми.<br/>
Нажимаем Create deploy token.<br/>
НЕ ЗАКРЫВАЕМ ОКНО БРАУЗЕРА!<br/>
Создаем image pull secret - для того, чтобы наш кластер Kubernetes мог получать образы из registry gitlab'а.<br/>
```
kubectl create secret docker-registry gitlab-registry --docker-server registry.gitlab.com --docker-email 'fyvaoldg@gmail.com' --docker-username '<первая строчка из окна создания токена в gitlab>' --docker-password '<вторая строчка из окна создания токена в gitlab>' --namespace prod
```
Создаем секрет для бд а также секрет с ключом от сервисного ака терраформа для sql proxy <br/>
```
kubectl create secret generic db \
  --from-literal=username=postgres \
  --from-literal=password=<YOUR-DATABASE-PASSWORD> \
  --from-literal=connectionname=<YOUR-INSTANCE_CONNECTION_NAME> \
  -n prod

#cd ../graduation_work_iac/

kubectl create secret generic cloudsql-instance-credentials \
--from-file=terraform.json=terraform.json \
-n prod

```
Также необходимо предсоздать БД для приложения - например, с VM раннера, предварительно поставив psql <br/>
```
gcloud compute ssh  gitlab-runner
sudo -i
apt install postgresql-client-common postgresql-client -y

psql -v ON_ERROR_STOP=1 -h <HOST> --username postgres -W <<-EOSQL
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
### Проверка переменных и пробный запуск
Итого, должны быть следущие переменные:

**graduation_work**: K8S_API_URL K8S_CI_TOKEN

**graduation_work_iac**: PROJECTID RUNNER_TOKEN SERVICEACCOUNT SQL_PASS

Проверяем, сделав пробный запуск (ну или можно сразу запустить пайплайн проекта с приллжением)<br/>

```
helm upgrade --install graduationapp .helm -f .helm/values.yaml --namespace prod

```
Если нужна диагностика - можно запустить под внутри кластера<br/>
```
kubectl run -t -i --rm --image centosadmin/utils test bash -n prod
apk --update add redis
apk --update add postgresql-client
psql -h yelb-db --username postgres -W

```
### Удаление или частичное отключение
Все удалить - terraform destroy и удалить раннер из списка раннеров. Иногда подзалипает удаление SQL - удаляем из консоли, затем, например<br/>
```
terraform state list
terraform state rm module.cloudsql.google_sql_user.user
terraform destroy
```
 Чтобы совсем окончательно все удадить - удалить баскет, и затем - отключить проект.<br/>
