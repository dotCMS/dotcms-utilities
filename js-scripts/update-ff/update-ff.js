// First of all, you can see in this script how there is a default configuration that we will use to create the config file
// Feel free to add more flags or change the default values before you run this script.
// This script will create a config file with the default values if it doesn't exist.
// Then it will prompt you whether you want to update the system table with new flags or not.
// If you choose to update the system table, it will prompt you to enable or disable the flags.
// After you choose the flags, it will update the system table with the new values and save the new config file.
// If you choose not to update the system table, it will update the system table with the current values.

// To make this script work, you need to delete all env variables you will use here to set the flags and run the script.
// This is because dotCMS system table is the last source of truth for the flags, so if you have env variables set, the system table will not be checked.
// Also you have to install the "prompts" package.

// In the future we will have a frontend for this, but for now, we can use this to update the flags easily.

import prompts from 'prompts';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { DOTCMS_SYSTEM_TABLE_API, BASIC_AUTH } from '../dot-config.js';

const __filename = fileURLToPath(import.meta.url);

const __dirname = path.dirname(__filename);

const configFile = path.join(__dirname, 'config.json');

let flags; // Our flags will be stored here after we read the config file

// This is the default configuration that we will use to create the config file
// Feel free to add more flags or change the default values before you run this script
const DEFAULT_ENV_CONFIG = {
    DOT_FEATURE_FLAG_EXPERIMENTS: { value: 'true', title: 'Enable Experiments' },
    DOT_DOTCMS_DEV_MODE: { value: 'true', title: 'Enable Dev Mode' },
    DOT_ENABLE_EXPERIMENTS_AUTO_JS_INJECTION: {
        value: 'true',
        title: 'Enable Experiments Auto JS Injection' // The title is what you will see in the prompt when you run the script
    },
    DOT_FEATURE_FLAG_SEO_IMPROVEMENTS: { value: 'true', title: 'Enable SEO Improvements' },
    DOT_FEATURE_FLAG_SEO_PAGE_TOOLS: { value: 'true', title: 'Enable SEO Page Tools' },
    DOT_FEATURE_FLAG_NEW_BINARY_FIELD: { value: 'true', title: 'Enable New Binary Field' },
    DOT_CONTENT_EDITOR2_ENABLED: { value: 'true', title: 'Enable new Edit Content' },
    FEATURE_FLAG_EDIT_URL_CONTENT_MAP: {
        value: 'true',
        title: 'Enable edit UrlContentMap from Edit Page'
    },
    FEATURE_FLAG_NEW_EDIT_PAGE: {
        value: 'true',
        title: 'Enable new Edit Page'
    }
};

function readConfig() {
    try {
        flags = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    } catch (error) {
        console.log(error);
    }
}

function postFeatureFlags(key, value) {
    return fetch(DOTCMS_SYSTEM_TABLE_API, {
        method: 'POST',
        headers: {
            Authorization: BASIC_AUTH,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            key,
            value
        })
    });
}

function exectUpdate(flags = flags) {
    Object.keys(flags).forEach((key) => {
        postFeatureFlags(key, flags[key].value).then((res) => {
            res.json()
                .then((data) => {
                    const color = flags[key].value == 'true' ? '\x1b[32m' : '\x1b[31m';

                    console.log('\x1b[35m%s\x1b[0m', data.entity);
                    console.log(`\x1b[${color}%s\x1b[0m`, `with value: ${flags[key].value}\n`);
                })
                .catch((err) => {
                    console.log(err);
                });
        });
    });
}

async function runPrompts() {
    const FF_KEYS = flags ? Object.keys(flags) : Object.keys(DEFAULT_ENV_CONFIG);

    const { value } = await prompts({
        type: 'confirm',
        name: 'value',
        message: 'Do you want to update the system table with new flags?',
        initial: false
    });

    if (!value) {
        // We execute the update with the current values
        exectUpdate(flags);
    } else {
        const choices = FF_KEYS.map((key) => {
            return {
                title: flags[key].title,
                value: key,
                selected: flags[key].value == 'true'
            };
        });

        const { value } = await prompts({
            type: 'multiselect',
            name: 'value',
            message: 'Enable Feature Flags',
            hint: '- Space to select. Return to submit',
            choices
        }); // This values are the keys that are on.

        const newJSON = FF_KEYS.reduce((acc, key) => {
            acc[key] = {
                ...flags[key],
                value: value.includes(key).toString()
            };

            return acc;
        }, {});

        exectUpdate(newJSON);
        fs.writeFile(configFile, JSON.stringify(newJSON, null, 2), { flag: 'w' }, (err) => {
            if (err) throw err;

            console.log('\x1b[33m%s\x1b[0m', 'The new config has been saved!\n');
        });
    }
}

// Create the config file with the default values if it doesn't exist
fs.writeFile(configFile, JSON.stringify(DEFAULT_ENV_CONFIG, null, 2), { flag: 'wx' }, (error) => {
    if (error) {
        console.log('We already have a config file!');
        readConfig();
    } else {
        console.log('Configuration file created with initial values!');
    }

    runPrompts();
});
