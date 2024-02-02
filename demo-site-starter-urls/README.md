You can install dotCMS with the "demo site" content as seen on https://demo.dotcms.com
by setting the CUSTOM_STARTER_URL environment variable.
This is great for testing and for learning your way around dotCMS.

The correct starter file url varies by dotCMS version.

The [dotcms-get-demo-site-starter-urls.sh](https://github.com/dotCMS/dotcms-utilities/blob/main/demo-site-starter-urls/dotcms-get-demo-site-starter-urls.sh) script prints the 
CUSTOM_STARTER_URL env var to use in docker-compose.yml or k8s

This env var must be present the first time you start dotCMS.
