#!/usr/bin/env bash

list_repos | while IFS= read -r repo ; do
  url="$(load_repo "$repo" url)"
  name=$(echo "$url" | cut -f5 -d/)
  path="$(load_repo "$repo" path)"

  SONAR_PROJECT_FILE=${WORKSPACE}/${path}/sonar-project.properties
  SONAR_DEFAULT_PROJECT_KEY=$name"-compliance-check"

  # NOTE - the following variables are set and exported in sonarqube_setup
  #   SONAR_HOST_URL
  #   SONAR_USER
  #   SONAR_PASS
  #   SONAR_TOKEN

  if [[ -n "$SONAR_TOKEN" ]]; then

    # copy the token out to the local file system so sonarqube_scan doesn't try to create a new token in sonarqube_scan
    echo "$SONAR_TOKEN" > /tmp/sonarqube-token

    if [[ -f $SONAR_PROJECT_FILE ]]; then
      debug "Using user provided 'sonar-project.properties' file"
      TEMP_FILE=${WORKSPACE}/${path}/new-sonar-project.properties

      while read -r LINE; do
        # skip blank lines
        if [[ -z "$LINE" ]]; then continue; fi

        if [[ $LINE == sonar.login* ]]; then
          : # don't copy this line at all, we will replace with our token
        elif [[ $LINE == sonar.password* ]]; then
          : # don't copy this line at all
        elif [[ $LINE == sonar.host.url* ]]; then
          : # don't copy this line, we will replace with the url from the server tool integration
        else
          echo "$LINE" >> "$TEMP_FILE"
        fi
      done < "$SONAR_PROJECT_FILE"
      echo "sonar.login=$SONAR_TOKEN" >> "$TEMP_FILE"
      echo "sonar.host.url=$SONAR_HOST_URL" >> "$TEMP_FILE"

      cp -f "$TEMP_FILE" "$SONAR_PROJECT_FILE"
    else
      {
        echo "sonar.projectKey=$SONAR_DEFAULT_PROJECT_KEY"
        echo "sonar.host.url=$SONAR_HOST_URL"
        echo "sonar.sources=."
        echo "sonar.login=$SONAR_TOKEN"
      } >> "$SONAR_PROJECT_FILE"
    fi

  else
    if [[ -f $SONAR_PROJECT_FILE ]]; then
      debug "Using user provided 'sonar-project.properties' file"
      TEMP_FILE=${WORKSPACE}/${path}/new-sonar-project.properties

      while read -r LINE; do
        # skip blank lines
        if [[ -z "$LINE" ]]; then continue; fi

        if [[ $LINE == sonar.login* ]]; then
          : # don't copy this line at all, we will replace with value from tool integration
        elif [[ $LINE == sonar.password* ]]; then
          : # don't copy this line at all, we will replace with value from tool integration
        elif [[ $LINE == sonar.host.url* ]]; then
          : # don't copy this line, we will replace with the url from the server tool integration
        else
          echo "$LINE" >> "$TEMP_FILE"
        fi
      done < "$SONAR_PROJECT_FILE"

      {
        echo "sonar.login=$SONAR_USER"
        echo "sonar.password=$SONAR_PASS"
        echo "sonar.host.url=$SONAR_HOST_URL"
      } >> "$TEMP_FILE"

      cp -f "$TEMP_FILE" "$SONAR_PROJECT_FILE"
    else
      {
        echo "sonar.projectKey=$SONAR_DEFAULT_PROJECT_KEY"
        echo "sonar.host.url=$SONAR_HOST_URL"
        echo "sonar.sources=."
        echo "sonar.login=$SONAR_USER"
        echo "sonar.password=$SONAR_PASS"
      } >> "$SONAR_PROJECT_FILE"
    fi
  fi
done
