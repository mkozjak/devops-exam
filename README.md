# Infrastructure
In order to deploy all the needed resources on an existing Kubernetes cluster (docker-desktop) for Helm to deploy applications to, we first need to bring Terraform to the desired state:

```sh
cd infra
terraform plan
terraform apply
```

We should now have following resources deployed:

1. MySQL database (service, deployment and pods)
2. ConfigMaps for database configuration
3. Secrets for database credentials
4. A ubuntu container for dev and testing purposes
5. Database fixtures with initial data.

# Application
After the previous section is done, we need to build our application locally and package it as a Docker image:

```sh
cd app
docker build -t devops-exam:1.0.0 .
```

We can now deploy our application to Kubernetes via Helm package manager:

```sh
cd infra/charts/app

# The password should be fed via CI/CD in order for this process to be secure
helm upgrade --install -f ./values.yaml --set database.password=shouldBeChanged app-dev .
```

Our application should now be up & running on port 80:

```sh
curl http://localhost:80

<h1>Users</h1><ul><li>Name: Eve, Email: eve@example.com</li><li>Name: John, Email: john@example.com</li></ul>
```

# Version bumping
In order to prepare our chart for the app update (potentially via a Continuous Deployment stage) we can run the following procedure:

```sh
cd utils
go mod download
go run bump_chart_app_version.go -c ../infra/charts/app/Chart.yaml
```

Available options are:

```sh
-n -- wanted app version
-c -- chart file
```

If `-n` is not provided, this tool will bump the version via semver **patch**.