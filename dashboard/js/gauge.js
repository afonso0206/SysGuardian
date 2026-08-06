import { getScoreMetadata, createSVGElement } from './utils.js';

export class GaugeComponent {
    render(containerId, score) {
        const container = document.getElementById(containerId);
        if (!container) return;
        container.innerHTML = '';

        const numericScore = parseFloat(score) || 0;
        const meta = getScoreMetadata(numericScore);

        const svg = createSVGElement('svg', {
            viewBox: '0 0 200 200',
            width: '200',
            height: '200'
        });

        // Track Arc
        const track = createSVGElement('path', {
            d: 'M 30 150 A 75 75 0 1 1 170 150',
            fill: 'none',
            stroke: 'var(--border-color)',
            'stroke-width': '16',
            'stroke-linecap': 'round'
        });

        // Value Arc Calculation
        const totalLen = 353.43; // Approximate arc circumference length
        const dashOffset = totalLen - (totalLen * (numericScore / 100));

        const valueArc = createSVGElement('path', {
            d: 'M 30 150 A 75 75 0 1 1 170 150',
            fill: 'none',
            stroke: meta.color,
            'stroke-width': '16',
            'stroke-linecap': 'round',
            'stroke-dasharray': totalLen,
            'stroke-dashoffset': dashOffset,
            style: 'transition: stroke-dashoffset 1s ease-in-out;'
        });

        svg.appendChild(track);
        svg.appendChild(valueArc);
        container.appendChild(svg);

        const scoreValEl = document.getElementById('overallScoreValue');
        const scoreClassEl = document.getElementById('overallScoreClassification');

        if (scoreValEl) {
            scoreValEl.textContent = `${numericScore}%`;
            scoreValEl.style.color = meta.color;
        }

        if (scoreClassEl) {
            scoreClassEl.textContent = meta.label;
            scoreClassEl.style.color = meta.color;
        }
    }
}