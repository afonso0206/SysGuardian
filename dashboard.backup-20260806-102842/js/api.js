/**
 * ============================================================
 * SysGuardian Dashboard
 * API Loader
 * ============================================================
 */

const API = {

    async loadLatestReport() {

        try {

            const response = await fetch(
                "api/latest.php?" + Date.now()
            );

            if (!response.ok)
                throw new Error("Erro ao carregar JSON.");

            return await response.json();

        } catch (e) {

            console.error(e);

            return null;

        }

    }

};