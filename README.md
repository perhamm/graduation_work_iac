Перед запуском нужно установить раннер в облаке, следоватьльно, первый запуск необходимо провести с локального компьютера.

Преполагается что gcloud, терраформ и kubectl установлен на этом самом локальном компьютере...

Удалить все старые auth - 

```gcloud auth revoke --all```

В консоли облака - создать новый проект - s015937 

У него будет уникальный id - например, s015937-335713

Зайти в iam-admin/serviceaccounts - сдлеать новый сервис аккаунт, назвать его terrafrom, дать роль owner и создать для него ключ JSON.

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

```
terraform init
terraform plan -var="gitlab_runner_registration_token=token"
terraform apply -var="gitlab_runner_registration_token=token"
```

Для доступа по ssh к гитлаб-раннеру, если он нужен по каким-либо причинам, проще всего провалиться в него через ```gcloud compute ssh  gitlab-runner```

Вносим ```cat terraform.json  | base64 -w0``` в переменную $SERVICEACCOUNT проекта graduation_work_iac в разделе CI/CD настроек.


