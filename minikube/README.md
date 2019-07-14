# Local Development Environment for Project KPI

The local development environment uses minikube to run a local kubernetes cluster.

For development convienience losts of passwords are just hard coded.

## Quickstart

You basically need a working minikube as description in the Minikube section.
After that just run ```make kpi-init``` and the cluster and the required resources as well as the database are initialized.

Please note the make kpi-init will update the /etc/hosts in case the minikube ip is not present and requires the sudo password.

There is a goal ```make grafana-launch``` which will start the default browser and open the grafana login url.

The first time you will be asked for the user name and password of grafana which is both ```admin```.

## Minikube

See minikube installation instructions.

```https://kubernetes.io/de/docs/tasks/tools/install-minikube/```

Currently working environments are:

- MAC-OS + Virtualbox (Marinus, Jonas)
- Linux + Virtualbox (Richard, Richard, Valentine)
- Linux + KVM + dmasq + libvirt

## Athene2 Database

In minikube the mysql instance runs in a pod and is exported to the local host using the node port 30020.

The database name is ```serlo``` and the user is ```root``` and the password is ```admin```.

With ```make athene2-db-import``` you can import the sql dump which is downloaded from glcoud dev environment.

## KPI Database

In minikube the postgres instance runs in a pod and is exported to the local host using the node port 30021.

The database name is ```kpi``` and the user is ```postgres``` and the password is set to  ```admin```.

## Grafana

Grafana is deployed as a service and is exposed via the ingress controller.

To access Grafana from the browser you need to add an entry into your /etc/hosts.

 [minikube ip]  stats.serlo.local mysql.serlo.local postgres.serlo.local

After that you can access it using https://stats.serlo.local/login

Use ```admin``` user with password ```admin```.
