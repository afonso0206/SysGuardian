import { CONFIG } from "./config.js";

export class SidebarComponent {

    constructor() {

        this.sidebar =
            document.getElementById("mainSidebar");

        this.toggleButton =
            document.getElementById("sidebarToggleBtn");

        this.mainWrapper =
            document.querySelector(".main-wrapper");

        this.collapsed =

            localStorage.getItem(

                CONFIG.STORAGE.SIDEBAR ?? "sysguardian_sidebar"

            ) === "true";

    }

    init() {

        this.apply();

        this.toggleButton?.addEventListener(

            "click",

            () => this.toggle()

        );

        document.addEventListener(

            "keydown",

            event => {

                if (

                    event.ctrlKey &&

                    event.key.toLowerCase() === "b"

                ) {

                    event.preventDefault();

                    this.toggle();

                }

            }

        );

    }

    toggle() {

        this.collapsed = !this.collapsed;

        this.apply();

    }

    collapse() {

        this.collapsed = true;

        this.apply();

    }

    expand() {

        this.collapsed = false;

        this.apply();

    }

    isCollapsed() {

        return this.collapsed;

    }

    apply() {

        this.sidebar?.classList.toggle(

            "collapsed",

            this.collapsed

        );

        this.mainWrapper?.classList.toggle(

            "sidebar-collapsed",

            this.collapsed

        );

        localStorage.setItem(

            CONFIG.STORAGE.SIDEBAR ?? "sysguardian_sidebar",

            this.collapsed

        );

        document.dispatchEvent(

            new CustomEvent(

                "sidebarChanged",

                {

                    detail: {

                        collapsed: this.collapsed

                    }

                }

            )

        );

    }

}
