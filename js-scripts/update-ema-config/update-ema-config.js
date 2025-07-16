import { DOTCMS_EMA_CONFIG_API, BASIC_AUTH } from '../dot-config.js';
import { getDemoSite } from '../utils.js';

const projectURL = process.argv[2] ?? 'http://localhost:3000'; // Fallback to localhost:3000 which is NextJS

const emaConfig = {
    // Basic config to test UVE Headless
    config: [
        {
            pattern: '.*',
            url: projectURL
        }
    ]
};

const stringEmaConfig = JSON.stringify(emaConfig);

const demoSite = await getDemoSite();

fetch(`${DOTCMS_EMA_CONFIG_API}${demoSite.identifier}`, {
    method: 'POST',
    headers: {
        Authorization: BASIC_AUTH,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        configuration: {
            hidden: false,
            value: stringEmaConfig
        }
    })
}).then((response) => {
    response.json().then((data) => {
        if (data.entity === 'Ok') console.log('EMA Config updated');
    });
});
