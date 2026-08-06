import { CONFIG } from "./config.js";

export class ThemeManager {

    constructor() {

        this.currentTheme =

            localStorage.getItem(

                CONFIG.STORAGE.THEME

            ) ||

            this.detectSystemTheme();

    }

    init() {

        this.applyTheme(this.currentTheme);

        window.addEventListener(

            "storage",

            event => {

                if (

                    event.key === CONFIG.STORAGE.THEME &&

                    event.newValue

                ) {

                    this.applyTheme(

                        event.newValue

                    );

                }

            }

        );

    }

    detectSystemTheme() {

        return window.matchMedia(

            "(prefers-color-scheme: dark)"

        ).matches

            ? "dark"

            : "light";

    }

    getTheme() {

        return this.currentTheme;

    }

    setTheme(theme) {

        this.currentTheme = theme;

        localStorage.setItem(

            CONFIG.STORAGE.THEME,

            theme

        );

        this.applyTheme(theme);

        document.dispatchEvent(

            new CustomEvent(

                "themeChanged",

                {

                    detail: {

                        theme

                    }

                }

            )

        );

    }

    applyTheme(theme) {

        document.documentElement.setAttribute(

            "data-theme",

            theme

        );

    }

    toggle() {

        this.setTheme(

            this.currentTheme === "dark"

                ? "light"

                : "dark"

        );

    }

}
