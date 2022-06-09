#!/bin/sh

docker_run="docker run"

if [ -n "$INPUT_MYSQL_ROOT_PASSWORD" ]; then
  echo "Root password not empty, use root superuser"

  docker_run="$docker_run -e MYSQL_ROOT_PASSWORD=$INPUT_MYSQL_ROOT_PASSWORD"
elif [ -n "$INPUT_MYSQL_USER" ]; then
  if [ -z "$INPUT_MYSQL_PASSWORD" ]; then
    echo "The mysql password must not be empty when mysql user exists"
    exit 1
  fi

  echo "Use specified user and password"

  docker_run="$docker_run -e MYSQL_RANDOM_ROOT_PASSWORD=true -e MYSQL_USER=$INPUT_MYSQL_USER -e MYSQL_PASSWORD=$INPUT_MYSQL_PASSWORD"
else
  echo "Both root password and superuser are empty, must contains one superuser"
  exit 1
fi

if [ -n "$INPUT_MYSQL_DATABASE" ]; then
  echo "Use specified database"

  docker_run="$docker_run -e MYSQL_DATABASE=$INPUT_MYSQL_DATABASE"
fi

docker_run="$docker_run -d -p $INPUT_HOST_PORT:$INPUT_CONTAINER_PORT mysql:$INPUT_MYSQL_VERSION --port=$INPUT_CONTAINER_PORT"
docker_run="$docker_run --character-set-server=$INPUT_CHARACTER_SET_SERVER --collation-server=$INPUT_COLLATION_SERVER"

sh -c "$docker_run"

# Setup user environment vars
if [[ ! -z $ENV_FILE_NAME ]]; then
    echo "Setting up your environment variables"
    python /setup_env_script.py
    . ./$SHELL_FILE_NAME
fi


export SETTINGS_FILE="./$INPUT_SETTINGS_PATH"
export SHELL_FILE_NAME="set_env.sh"
export ENV_FILE_NAME=$INPUT_ENV_FILE


pip install setuptools-scm==5.0.2
pip install -r $INPUT_REQUIREMENTS_FILE
echo "Migrating DB"
python2 manage.py migrate

echo "Running your tests"

# TODO: Find a better alternative
if [ "$INPUT_PARALLEL_TESTS" == "true" ]; then
    echo "Enabled Parallel Testing"
    python2 manage.py test --parallel
else 
    python2 manage.py test $INPUT_TEST_APPS
fi

