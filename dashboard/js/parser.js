/**
 * ============================================================
 * SysGuardian Dashboard
 * Report Parser
 * ============================================================
 */

export const ReportParser = {

    parse(report) {

        if (!report || typeof report !== 'object') {
            throw new Error('Relatório inexistente.');
        }

        if (!report.metadata || typeof report.metadata !== 'object') {
            throw new Error('Metadata ausente.');
        }

        return {

            metadata: {
                hostname: report.metadata.hostname || 'Desconhecido',
                date: report.metadata.date || '',
                version: report.metadata.version || '',
                score: Number(report.metadata.score) || 0,
                classification: report.metadata.classification || 'N/A'
            },

            category_scores:
                (report.category_scores &&
                 typeof report.category_scores === 'object')
                    ? report.category_scores
                    : {},

            entries:
                Array.isArray(report.entries)
                    ? report.entries
                    : [],

            printers:
                (report.printers &&
                 typeof report.printers === 'object' &&
                 !Array.isArray(report.printers))
                    ? report.printers
                    : null

        };

    },

    getAlerts(report) {

        return (report.entries || []).filter(item =>
            item.level === 'WARN' ||
            item.level === 'ERROR'
        );

    },

    getCategory(report, category) {

        return report.category_scores?.[category] ?? 0;

    }

};
