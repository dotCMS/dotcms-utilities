import { DOTCMS_EXP_CONFIG_API, BASIC_AUTH } from '../dot-config.js';
import { getDemoSite } from '../utils.js';

// This is the config for testing experiments locally
const expConfig = {
    clientId: {
        hidden: false,
        value: 'analytics-customer-customer1'
    },
    clientSecret: {
        hidden: true,
        value: 'testsecret'
    },
    analyticsConfigUrl: {
        hidden: false,
        value: 'http://host.docker.internal:8088/c/customer1/cluster1/keys'
    },
    analyticsWriteUrl: {
        hidden: false,
        value: 'http://host.docker.internal:8081/api/v1/event'
    },
    analyticsReadUrl: {
        hidden: false,
        value: 'http://host.docker.internal:4001/'
    }
};

const demoSite = await getDemoSite();

fetch(`${DOTCMS_EXP_CONFIG_API}${demoSite.identifier}`, {
    method: 'POST',
    headers: {
        Authorization: BASIC_AUTH,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(expConfig)
}).then((response) => {
    response.json().then((data) => {
        if (data.entity === 'Ok') console.log('Experiments Config updated');
    });
});
