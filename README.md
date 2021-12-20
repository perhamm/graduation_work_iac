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
gcloud services enable compute.googleapis.com  container.googleapis.com  sql-component.googleapis.com sqladmin.googleapis.com  servicenetworking.googleapis.com cloudresourcemanager.googleapis.com
gcloud config set compute/zone europe-west3-a
gcloud config set compute/region europe-west3

```

Первое применение терраформа - с локального компа.

Сначала создать баскет в Cloud Storage с именем s015937-terraform-state

Взять токен из раздела настроек раннеров, отключить шаренные раннеры.

```
terraform init
terraform plan -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713"
terraform apply -var="gitlab_runner_registration_token=token" -var="project_id=s015937-335713"
```

Для доступа по ssh к гитлаб-раннеру, если он нужен по каким-либо причинам, проще всего провалиться в него через ```gcloud compute ssh  gitlab-runner```

Вносим ```cat terraform.json  | base64 -w0``` в переменную $SERVICEACCOUNT проекта graduation_work_iac в разделе CI/CD настроек. Тудаже вносим PROJECTID, например, s015937-335713, и RUNNER_TOKEN. На этом этапе, если появился раннер в настройках - пайпланы должны заработать.

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

Все удалить - terraform destroy и удалить раннер из списка раннеров. Затем удалить баскет, и затем - отключить проект.
