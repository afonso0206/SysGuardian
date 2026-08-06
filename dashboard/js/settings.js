import { CONFIG } from "./config.js";

export class SettingsComponent {

    constructor(themeManager, onRefreshChange = null) {

        this.themeManager = themeManager;

        this.onRefreshChange = onRefreshChange;

        this.themeSelect = null;

        this.refreshSelect = null;

    }

    init() {

        this.themeSelect =

            document.getElementById(

                "settingsThemeSelect"

            );

        this.refreshSelect =

            document.getElementById(

                "settingsRefreshSelect"

            );

        this.populateRefreshOptions();

        this.load();

        this.bindEvents();

    }

    bindEvents() {

        this.themeSelect?.addEventListener(

            "change",

            event => {

                this.themeManager.setTheme(

                    event.target.value

                );

                this.save();

            }

        );

        this.refreshSelect?.addEventListener(

            "change",

            event => {

                const interval =

                    Number(event.target.value);

                localStorage.setItem(

                    CONFIG.STORAGE.REFRESH_INTERVAL,

                    interval

                );

                if (typeof this.onRefreshChange === "function")

                    this.onRefreshChange(interval);

                document.dispatchEvent(

                    new CustomEvent(

                        "refreshIntervalChanged",

                        {

                            detail: {

                                interval

                            }

                        }

                    )

                );

            }

        );

    }

    populateRefreshOptions() {

        if (!this.refreshSelect)
            return;

        this.refreshSelect.replaceChildren();

        CONFIG.REFRESH_OPTIONS.forEach(option => {

            const element =

                document.createElement("option");

            element.value = option.value;

            element.textContent = option.label;

            this.refreshSelect.appendChild(element);

        });

    }

    load() {

        if (this.themeSelect) {

            this.themeSelect.value =

                this.themeManager.getTheme();

        }

        if (this.refreshSelect) {

            const stored =

                localStorage.getItem(

                    CONFIG.STORAGE.REFRESH_INTERVAL

                ) ??

                CONFIG.DASHBOARD.AUTO_REFRESH_DEFAULT;

            this.refreshSelect.value = stored;

        }

    }

    save() {

        localStorage.setItem(

            CONFIG.STORAGE.THEME,

            this.themeManager.getTheme()

        );

    }

    reset() {

        localStorage.removeItem(

            CONFIG.STORAGE.THEME

        );

        localStorage.removeItem(

            CONFIG.STORAGE.REFRESH_INTERVAL

        );

        this.load();

    }

}
