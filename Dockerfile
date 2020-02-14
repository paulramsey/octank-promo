FROM jboss/wildfly
COPY target/promotion-0.0.1-SNAPSHOT.war /opt/jboss/wildfly/standalone/deployments/promotion.war
