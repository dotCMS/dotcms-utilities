import { BASIC_AUTH, DOTCMS_COMPANY_INFO_API } from '../dot-config.js';
import queryString from 'querystring';

const primaryColor = process.argv[2] ?? '#426BF0'; // Fallback to design system color
const secondaryColor = process.argv[3] ?? '#7042F0'; // Fallback to design system color

// This is the data that is for default in this endpoint, I just changed the colors
const formData = {
    portalURL: 'localhost',
    mx: '',
    emailAddress: 'dotCMS Website <website@dotcms.com>',
    size: '#1b3359',
    type: primaryColor,
    street: secondaryColor,
    homeURL: '/html/images/backgrounds/bg-11.jpg',
    city: '/dA/bc66ae086e242991d89e386d353c7529/asset/dotCMS-400x200.png'
};

const body = `portalURL=${queryString.encode(formData)}`; // We need to encode the object to send it as a string

fetch(DOTCMS_COMPANY_INFO_API, {
    headers: {
        accept: '*/*',
        Authorization: BASIC_AUTH,
        'content-type': 'application/x-www-form-urlencoded'
    },
    body,
    method: 'POST'
}).then((response) => {
    if (response.ok) {
        response.text().then(() => {
            console.log('Colors updated\n', {
                primaryColor,
                secondaryColor
            });
        });
    } else {
        console.log('Something occured while updating the colors');
    }
});
