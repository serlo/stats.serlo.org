FROM eu.gcr.io/serlo-shared/grafana:6.2.5
ARG git_revision
ENV GIT_REVISION $git_revision
USER root
RUN apt-get update && apt-get install -qq -y jq
ADD ./provisioning.yml /etc/grafana/provisioning/dashboards/local.yml
ADD dashboards/*.json /tmp/grafana/dashboards/
ADD ./init.sh /tmp/init.sh
ADD ./entry.sh /entry.sh
RUN chmod a+x /tmp/init.sh && chmod a+x /entry.sh 
USER grafana
ENTRYPOINT ["/entry.sh"]
