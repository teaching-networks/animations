# Renew version overview

On the server `www.sam.cs.hm.edu` we deploy a version overview of all the available application versions: https://www.sam.cs.hm.edu/version/.

The `renew_version_html.sh` script is executed in the `.gitlab-ci.yml` build script after a new version is deployed and will update the HTML file of the version overview.

Call `./renew_version_html.sh --help` to see the available options.
