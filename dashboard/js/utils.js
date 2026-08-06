import { CONFIG } from './config.js';

/**
 * ============================================================
 * Score
 * ============================================================
 */

export function getScoreMetadata(score) {

    const value = Number(score) || 0;

    const thresholds = CONFIG.SCORE;

    if (value >= thresholds.EXCELENTE.min) return thresholds.EXCELENTE;
    if (value >= thresholds.BOM.min) return thresholds.BOM;
    if (value >= thresholds.REGULAR.min) return thresholds.REGULAR;
    if (value >= thresholds.RUIM.min) return thresholds.RUIM;

    return thresholds.CRITICO;

}

/**
 * ============================================================
 * Escape HTML
 * ============================================================
 */

export function escapeHTML(text) {

    if (typeof text !== "string")
        return text;

    return text.replace(/[&<>'"]/g, character => ({

        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "'": "&#39;",
        "\"": "&quot;"

    })[character]);

}

/**
 * ============================================================
 * SVG
 * ============================================================
 */

export function createSVGElement(tag, attributes = {}) {

    const element = document.createElementNS(

        "http://www.w3.org/2000/svg",

        tag

    );

    Object.entries(attributes).forEach(

        ([key, value]) =>

            element.setAttribute(key, value)

    );

    return element;

}

/**
 * ============================================================
 * Date Formatter
 * ============================================================
 */

export function formatDate(date) {

    if (!date)
        return "-";

    return new Intl.DateTimeFormat(

        CONFIG.DASHBOARD.DATE_LOCALE,

        {

            dateStyle: "short",

            timeStyle: "medium"

        }

    ).format(new Date(date));

}

/**
 * ============================================================
 * Number Formatter
 * ============================================================
 */

export function formatNumber(value, digits = 0) {

    return Number(value).toLocaleString(

        CONFIG.DASHBOARD.DATE_LOCALE,

        {

            minimumFractionDigits: digits,

            maximumFractionDigits: digits

        }

    );

}

/**
 * ============================================================
 * Clamp
 * ============================================================
 */

export function clamp(value, min = 0, max = 100) {

    return Math.min(

        max,

        Math.max(min, value)

    );

}

/**
 * ============================================================
 * DOM
 * ============================================================
 */

export function $(selector, parent = document) {

    return parent.querySelector(selector);

}

export function $$(selector, parent = document) {

    return [...parent.querySelectorAll(selector)];

}

/**
 * ============================================================
 * Debounce
 * ============================================================
 */

export function debounce(callback, delay = 300) {

    let timer;

    return (...args) => {

        clearTimeout(timer);

        timer = setTimeout(

            () => callback(...args),

            delay

        );

    };

}
