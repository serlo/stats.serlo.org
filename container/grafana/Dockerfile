FROM eu.gcr.io/serlo-shared/grafana:6.2.5
ARG git_revision
ENV GIT_REVISION $git_revision
ADD ./provisioning.yml /etc/grafana/provisioning/dashboards/local.yml
ADD dashboards/*.json /tmp/grafana/dashboards/
