import fs from 'fs';
import { DOTCMS_USER, DOTCMS_TOKEN_API } from '../dot-config.js';

const DOTCMS_PATH = '/Users/zjaaal/Desktop/repos/dotcms'; // Change this to your dotcms path, this can be an env var

const label = (Math.random() + 1).toString(36).substring(7); // This generates a random string to label the token

const project = process.argv[2] ?? 'nextjs'; // You can pass an argument to specify the project (probably in the future we will have vue, astro, etc). if not it will default to nextjs

// Now that we are introducing new technologies to ema, we can have different configurations for each project
const configByProject = {
    nextjs: {
        tokenLabel: 'NEXT_PUBLIC_DOTCMS_AUTH_TOKEN', // Label we use in the .env.local file
        path: `${DOTCMS_PATH}/core/examples/nextjs/.env.local`, // Path to the .env.local file
        regex: 'NEXT_PUBLIC_DOTCMS_AUTH_TOKEN=.*', // Regex to find the token in the file
        quotes: false, // If the token is wrapped in quotes
        separator: '=' // Separator between the token label and the token
    },
    vuejs: {
        tokenLabel: 'VITE_DOTCMS_TOKEN',
        path: `${DOTCMS_PATH}/core/examples/vuejs/.env.local`,
        regex: 'VITE_DOTCMS_TOKEN=.*',
        quotes: false,
        separator: '='
    },
    angular: {
        tokenLabel: 'authToken',
        path: `${DOTCMS_PATH}/core/examples/angular/src/environments/environment.development.ts`,
        regex: 'authToken:.*',
        quotes: true,
        separator: ':'
    }
};

// We can make this function a common util
fetch(DOTCMS_TOKEN_API, {
    method: 'POST',
    headers: {
        accept: 'application/json',
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        user: DOTCMS_USER.username,
        password: DOTCMS_USER.password,
        expirationDays: 30,
        label
    })
})
    .then((response) => response.json())
    .then((data) => {
        const token = data.entity.token; // This is the token that we will use to authenticate the requests

        const { tokenLabel, path, regex, quotes, separator } = configByProject[project];
        // Read the file
        fs.readFile(path, 'utf8', (err, data) => {
            if (err) {
                console.error(err);
                return;
            }

            const tokenRegex = new RegExp(regex);

            const tokenReplacement = quotes
                ? `${tokenLabel}${separator}"${token}",`
                : `${tokenLabel}${separator}${token}`;

            // Find the token
            const result = data.replace(tokenRegex, tokenReplacement);

            // Write the file with the new token
            fs.writeFile(path, result, 'utf8', (err) => {
                if (err) {
                    console.error(err);
                    return;
                }

                console.log('Token updated');
            });
        });
    })
    .catch((error) => {
        console.error('Error:', error);
    });
