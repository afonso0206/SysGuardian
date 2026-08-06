/**
 * ============================================================
 * SysGuardian Dashboard
 * Global Configuration
 * ============================================================
 */

export const CONFIG = Object.freeze({

    APP: Object.freeze({

        NAME: "SysGuardian Dashboard",

        VERSION: "1.0.0"

    }),

    API: Object.freeze({

        ENDPOINT: "api/latest.php",

        TIMEOUT: 10000,

        CACHE: false

    }),

    STORAGE: Object.freeze({

        THEME: "sysguardian_theme",

        REFRESH_INTERVAL: "sysguardian_refresh_int"

    }),

    REFRESH_OPTIONS: Object.freeze([

        { label: "OFF", value: 0 },

        { label: "30s", value: 30000 },

        { label: "60s", value: 60000 },

        { label: "120s", value: 120000 },

        { label: "300s", value: 300000 }

    ]),

    SCORE: Object.freeze({

        EXCELENTE: {

            min: 95,

            color: "#10b981",

            label: "EXCELENTE"

        },

        BOM: {

            min: 80,

            color: "#3b82f6",

            label: "BOM"

        },

        REGULAR: {

            min: 60,

            color: "#f59e0b",

            label: "REGULAR"

        },

        RUIM: {

            min: 40,

            color: "#f97316",

            label: "RUIM"

        },

        CRITICO: {

            min: 0,

            color: "#ef4444",

            label: "CRÍTICO"

        }

    }),

    DASHBOARD: Object.freeze({

        MAX_ALERTS: 10,

        ANIMATION_TIME: 1200,

        AUTO_REFRESH_DEFAULT: 60000,

        DATE_LOCALE: "pt-BR"

    }),

    DEBUG: false

});
