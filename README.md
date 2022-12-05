# greengrass-tools
some tools to help working with greengrass
**update--ggdeployment.sh** is a handy script to update a deployment with 1 new version of a component and leaves all the other components in the deployment as they are.

call update-deployment like:

    ./update-deployment -d 7kLatest -g 7kLatest -c au.com.mtdata.smartdvr.docker -v 0.0.3

where

     -d = the deplayment name
     -g = the deploayment group anme
     -c = the componennt name to update
     -v = the version of the component to update to