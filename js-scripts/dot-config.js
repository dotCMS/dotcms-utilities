// This can be env vars configured by the developer
export const DOTCMS_HOST = 'http://localhost:8080';
export const DOTCMS_USER = {
    username: 'admin@dotcms.com',
    password: 'admin'
};

// API Endpoints
export const DOTCMS_SYSTEM_TABLE_API = `${DOTCMS_HOST}/api/v1/system-table`;
export const DOTCMS_TOKEN_API = `${DOTCMS_HOST}/api/v1/authentication/api-token`;
export const DOTCMS_EMA_CONFIG_API = `${DOTCMS_HOST}/api/v1/apps/dotema-config-v2/`;
export const DOTCMS_EXP_CONFIG_API = `${DOTCMS_HOST}/api/v1/apps/dotAnalytics-config/`;
export const DOTCMS_SITES_API = `${DOTCMS_HOST}/api/v1/site?filter=*&per_page=15&archive=false`;
export const DOTCMS_COMPANY_INFO_API = `${DOTCMS_HOST}/api/config/saveCompanyBasicInfo`;

// Common Constants
export const BTOA_USER = btoa(`${DOTCMS_USER.username}:${DOTCMS_USER.password}`);
export const BASIC_AUTH = `Basic ${BTOA_USER}`;
export const DOTCMS_JVM_INFO_API = `${DOTCMS_HOST}/api/v1/jvm`;
export const DEMO_SITE_HOSTNAME = 'demo.dotcms.com';
