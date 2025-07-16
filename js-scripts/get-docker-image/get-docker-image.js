import { BASIC_AUTH, DOTCMS_JVM_INFO_API } from '../dot-config.js';

const DOCKER_TAG = 'dotcms/dotcms:trunk_';

// Just get the current Docker Image
fetch(DOTCMS_JVM_INFO_API, {
    method: 'GET',
    headers: {
        accept: '*/*',
        Authorization: BASIC_AUTH
    }
}).then((response) => {
    if (response.ok) {
        response.json().then((data) => {
            console.log(`DotCMS Docker Image: [${DOCKER_TAG + data.release.buildNumber}]`);
        });
    } else {
        console.log('Something occured while fetching the JVM information');
    }
});
