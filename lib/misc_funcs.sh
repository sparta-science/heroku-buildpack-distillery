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
  AWS_CLI_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"

  # parse and derive params
  BUILD_DIR=$1
  CACHE_DIR=$2
  BUILDPACK_DIR=$3

  echo "-----> Fetching AWS CLI into slug"
  curl --progress-bar -o /tmp/awscli-bundle.zip $AWS_CLI_URL
  unzip -qq -d "$BUILD_DIR/vendor" /tmp/awscli-bundle.zip

#  echo "-----> adding installer script into app/.profile.d"
#  mkdir -p $BUILD_DIR/.profile.d
#  cp "$BUILDPACK_DIR/bin/install_awscli.sh" $BUILD_DIR/.profile.d/
#  chmod +x $BUILD_DIR/.profile.d/install_awscli.sh

  AWS_INSTALL_DIR=$BUILD_DIR/vendor/awscli
  chmod +x $BUILD_DIR/vendor/awscli-bundle/install
  $BUILD_DIR/vendor/awscli-bundle/install -i $AWS_INSTALL_DIR
  chmod u+x $AWS_INSTALL_DIR/bin/aws

  export aws=$AWS_INSTALL_DIR/bin/aws

  #cleaning up...
  rm -rf /tmp/awscli*

  echo "-----> aws cli installation done"
}

create_aws_credentials() {
  mkdir ~/.aws

  cat >> ~/.aws/credentials << EOF
[default]
aws_access_key_id = $AWS_KEY
aws_secret_access_key = $AWS_SECRET_KEY
EOF

  cat >> ~/.aws/config << EOF
[default]
region = $AWS_REGION
EOF
  echo "-----> AWS credentials created"

}
