#!/bin/bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

echo "Configuring Keycloak by modifying realm and user templates..."

cat /scripts/che-users-0.json.erb | \
                                  sed -e "/<% if scope.lookupvar('keycloak::che_keycloak_admin_require_update_password') == 'true' -%>/d" | \
                                  sed -e "/<% else -%>/d" | \
                                  sed -e "/<% end -%>/d" | \
                                  sed -e "/\"requiredActions\" : \[ \],/d" > /scripts/che-users-0.json

cp /scripts/master-users-0.json.erb /scripts/master-users-0.json
cp /scripts/master-realm.json.erb /scripts/master-realm.json

if [ "${CHE_KEYCLOAK_ADMIN_REQUIRE_UPDATE_PASSWORD}" == "false" ]; then
    sed -i -e "s#\"UPDATE_PASSWORD\"##" /scripts/che-users-0.json
fi

cat /scripts/che-realm.json.erb | \
                                sed -e "s@<%= scope\.lookupvar('che::che_server_url') %>@${PROTOCOL}://che-${NAMESPACE}.${ROUTING_SUFFIX}@" \
                                > /scripts/che-realm.json

echo "Starting Keycloak server..."

/opt/jboss/keycloak/bin/standalone.sh -Dkeycloak.migration.action=import \
                                      -Dkeycloak.migration.provider=dir \
                                      -Dkeycloak.migration.strategy=IGNORE_EXISTING \
                                      -Dkeycloak.migration.dir=/scripts/ \
                                      -Djboss.bind.address=0.0.0.0
