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

function load_config() {
  build_dir=$1
  build_pack_dir=$2

  echo "-----> Checking Distillery app name and S3 root ..."

  local custom_config_file="${build_dir}/distillery_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_dir}/distillery_buildpack.config"

  if [ -f $custom_config_file ];
  then
    source $custom_config_file
  else
    echo "-----> WARNING: distillery_buildpack.config wasn't found in the app"
    echo "-----> Using default config from distillery buildpack"
  fi

  echo "-----> Will use the following versions:"
  echo "----->   * distillery_app_name ${distillery_app_name}"
  echo "----->   * s3_releases_root ${s3_releases_root}"
}

download_aws_cli() {
  # Perhaps try this to create a signed URL instead of using the AWS CLI?  https://github.com/paulhammond/s3-tarball-buildpack
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