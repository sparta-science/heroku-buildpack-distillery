Heroku buildpack: Distillery
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows one to download and run an Elixir Distillery release.

Usage
-----

## Configuration

Create a `distillery_buildpack.config` file in your app's root dir. The file's syntax is bash.

If you don't specify a config option, then the default option from the buildpack's 
[`distillery_buildpack.config`](https://github.com/sparta-science/heroku-buildpack-distillery/blob/master/distillery_buildpack.config) 
file will be used.

There are two config variables:

    distillery_app_name - the name of your Distillery app
    s3_releases_root - The URL of your private S3 bucket

Note that it is assumed that your distillery release is in a private S3 bucket of the form

    s3_releases_root/your_app/<CURRENT_APP_VERSION>/unix_linux/your_app.tar.gz

where the current version of your app is stored in a file:

    s3_releases_root/your_app/CURRENT_APP_VERSION

For example, for version 1.23.0 of the app "half_dome" with an s3 root of "s3://sparta-science", we assume the file:

    s3://sparta-science/half_dome/CURRENT_APP_VERSION
    
contains "1.23.0", and the actual release is at:

    s3://sparta-science/half_dome/1.23.0/unix_linux/half_dome.tar.gz

Example usage:

    $ heroku buildpacks:add https://github.com/sparta-science/heroku-buildpack-distillery.git

    $ heroku config:add AWS_ACCESS_KEY_ID=<aws-access-key>

    $ heroku config:add AWS_SECRET_ACCESS_KEY=<aws-secret-access-key>

    $ heroku config:add AWS_DEFAULT_REGION=<default-aws-region>
    
    $ git push heroku master

## Credits

&copy; Sparta Science under The MIT License. Feel free to do whatever you want with it.
