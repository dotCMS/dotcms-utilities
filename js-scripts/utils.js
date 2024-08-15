import { DOTCMS_SITES_API, BASIC_AUTH, DEMO_SITE_HOSTNAME } from './dot-config.js';

export async function getDemoSite() {
    const response = await fetch(DOTCMS_SITES_API, {
        method: 'GET',
        headers: {
            Authorization: BASIC_AUTH
        }
    });

    const data = await response.json();

    return data.entity.find((site) => site.hostname === DEMO_SITE_HOSTNAME);
}
