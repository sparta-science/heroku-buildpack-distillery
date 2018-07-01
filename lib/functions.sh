# A boilerplate function copied from: https://devcenter.heroku.com/articles/buildpack-api
export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

download_aws_cli() {
  build_dir=$1

  AWS_INSTALL_DIR=$build_dir/vendor/awscli
  AWS_CLI_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"

  echo "-----> Fetching AWS CLI into slug ..."
  curl --progress-bar -o /tmp/awscli-bundle.zip $AWS_CLI_URL
  unzip -qq -d "$build_dir/vendor" /tmp/awscli-bundle.zip

  chmod +x $build_dir/vendor/awscli-bundle/install
  $build_dir/vendor/awscli-bundle/install -i $AWS_INSTALL_DIR
  chmod u+x $AWS_INSTALL_DIR/bin/aws

  export aws=$AWS_INSTALL_DIR/bin/aws

  # cleaning up...
  rm -rf /tmp/awscli*

  echo "-----> AWS CLI installation completed"
}

create_aws_credentials() {
  aws_key=$1
  aws_secret_key=$2
  aws_region=$3

  mkdir ~/.aws

  cat >> ~/.aws/credentials << EOF
[default]
aws_access_key_id = $aws_key
aws_secret_access_key = $aws_secret_key
EOF

  cat >> ~/.aws/config << EOF
[default]
region = $aws_region
EOF
  echo "-----> AWS credentials created"
}

download_distillery_release_from_s3() {
  distillery_app_name=$1
  s3_releases_root=$2

  $aws s3 cp "${s3_releases_root}/${distillery_app_name}/CURRENT_APP_VERSION" /tmp/CURRENT_APP_VERSION
  app_version=`cat /tmp/CURRENT_APP_VERSION`

  echo "-----> app_version: ${app_version}"
  $aws s3 cp "${s3_releases_root}/${distillery_app_name}/${app_version}/unix_linux/${distillery_app_name}.tar.gz" /tmp

  echo "-----> Successfully downloaded version ${app_version} of ${distillery_app_name}.tar.gz"
}

untar_distillery_release() {
  distillery_app_name=$1
  build_dir=$2

  cd $build_dir
  # junk is temporarily here:
  mkdir junk
  cd junk

  tar xf /tmp/${distillery_app_name}.tar.gz
  echo "-----> Successfully untarred distillery application ${distillery_app_name}"
}