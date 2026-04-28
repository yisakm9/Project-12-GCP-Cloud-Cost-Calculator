// frontend/public/script.js
//
// GCP Cloud Cost Calculator — Dashboard Controller
// Fetches cost data from the Cloud Function API and renders
// summary cards, Chart.js visualizations, and the cost table.

// ──────────────────────────────────────────────
//  Configuration
//  This placeholder is replaced by the CI/CD pipeline with the
//  actual Cloud Function URL during deployment.
// ──────────────────────────────────────────────
const API_ENDPOINT = '%%API_ENDPOINT%%';

// GCP brand color palette for charts
const GCP_COLORS = [
    '#4285F4', '#34A853', '#FBBC04', '#EA4335',
    '#1a73e8', '#1e8e3e', '#f9a825', '#d93025',
    '#7baaf7', '#57bb8a', '#fdd663', '#e37400',
    '#a855f7', '#06b6d4', '#f97316', '#ec4899',
    '#8b5cf6', '#14b8a6', '#eab308', '#ef4444',
];

// Chart instances (for cleanup on refresh)
let barChartInstance = null;
let doughnutChartInstance = null;

// ──────────────────────────────────────────────
//  Initialization
// ──────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    fetchCostData();
});

function refreshData() {
    const btn = document.getElementById('refresh-btn');
    btn.classList.add('spinning');
    fetchCostData().finally(() => {
        setTimeout(() => btn.classList.remove('spinning'), 600);
    });
}

// ──────────────────────────────────────────────
//  Data Fetching
// ──────────────────────────────────────────────
async function fetchCostData() {
    const apiUrl = `${API_ENDPOINT}/costs`;

    try {
        updateTimestamp('Fetching...');
        console.log(`[CostCalc] Fetching data from: ${apiUrl}`);

        const response = await fetch(apiUrl, { method: 'GET' });

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`API returned status ${response.status}: ${errorBody}`);
        }

        const data = await response.json();
        renderDashboard(data);
        updateTimestamp(`Updated ${new Date().toLocaleTimeString()}`);

    } catch (error) {
        console.error('[CostCalc] Fetch error:', error);
        renderError(error.message);
        updateTimestamp('Failed to load');
    }
}

// ──────────────────────────────────────────────
//  Render: Full Dashboard
// ──────────────────────────────────────────────
function renderDashboard(data) {
    renderSummaryCards(data);
    renderBarChart(data.costsByService);
    renderDoughnutChart(data.costsByService);
    renderCostTable(data);
}

// ──────────────────────────────────────────────
//  Render: Summary Cards
// ──────────────────────────────────────────────
function renderSummaryCards(data) {
    // Net cost
    document.getElementById('total-cost-value').textContent =
        `$${data.totalCost.toFixed(2)}`;

    // Credits
    const creditsAbs = Math.abs(data.totalCredits || 0);
    document.getElementById('credits-value').textContent =
        creditsAbs > 0 ? `-$${creditsAbs.toFixed(2)}` : '$0.00';

    // Active services
    document.getElementById('services-value').textContent =
        data.serviceCount || data.costsByService.length;

    // Reporting period
    const start = data.reportingPeriod.start;
    const end = data.reportingPeriod.end;
    document.getElementById('period-value').textContent =
        `${formatDate(start)} — ${formatDate(end)}`;
}

// ──────────────────────────────────────────────
//  Render: Bar Chart (Cost by Service)
// ──────────────────────────────────────────────
function renderBarChart(services) {
    if (barChartInstance) barChartInstance.destroy();

    const ctx = document.getElementById('barChart').getContext('2d');
    const labels = services.map(s => truncateLabel(s.service, 28));
    const costs = services.map(s => s.cost);
    const colors = services.map((_, i) => GCP_COLORS[i % GCP_COLORS.length]);

    barChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Net Cost (USD)',
                data: costs,
                backgroundColor: colors.map(c => c + '33'),
                borderColor: colors,
                borderWidth: 1.5,
                borderRadius: 6,
                borderSkipped: false,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'y',
            layout: {
                padding: { right: 20 }
            },
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: 'rgba(17, 24, 39, 0.95)',
                    titleColor: '#f1f5f9',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(66, 133, 244, 0.3)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    titleFont: { family: 'Inter', weight: '600' },
                    bodyFont: { family: 'Inter' },
                    callbacks: {
                        label: (ctx) => ` $${ctx.parsed.x.toFixed(2)}`
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255,255,255,0.04)',
                        drawBorder: false,
                    },
                    ticks: {
                        color: '#64748b',
                        font: { family: 'Inter', size: 11 },
                        callback: (v) => `$${v}`
                    }
                },
                y: {
                    grid: { display: false },
                    ticks: {
                        color: '#94a3b8',
                        font: { family: 'Inter', size: 11 },
                        padding: 8,
                    }
                }
            }
        }
    });
}

// ──────────────────────────────────────────────
//  Render: Doughnut Chart (Cost Distribution)
// ──────────────────────────────────────────────
function renderDoughnutChart(services) {
    if (doughnutChartInstance) doughnutChartInstance.destroy();

    const ctx = document.getElementById('doughnutChart').getContext('2d');
    const top5 = services.slice(0, 5);
    const otherCost = services.slice(5).reduce((sum, s) => sum + s.cost, 0);

    const labels = top5.map(s => truncateLabel(s.service, 22));
    const costs = top5.map(s => s.cost);
    const colors = top5.map((_, i) => GCP_COLORS[i]);

    if (otherCost > 0) {
        labels.push('Other Services');
        costs.push(otherCost);
        colors.push('#475569');
    }

    const totalCost = costs.reduce((a, b) => a + b, 0);

    doughnutChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: costs,
                backgroundColor: colors.map(c => c + 'cc'),
                borderColor: 'rgba(10, 14, 26, 0.8)',
                borderWidth: 2,
                hoverOffset: 6,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '65%',
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        color: '#94a3b8',
                        font: { family: 'Inter', size: 11 },
                        padding: 16,
                        usePointStyle: true,
                        pointStyleWidth: 10,
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(17, 24, 39, 0.95)',
                    titleColor: '#f1f5f9',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(66, 133, 244, 0.3)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    titleFont: { family: 'Inter', weight: '600' },
                    bodyFont: { family: 'Inter' },
                    callbacks: {
                        label: (ctx) => {
                            const pct = ((ctx.parsed / totalCost) * 100).toFixed(1);
                            return ` $${ctx.parsed.toFixed(2)} (${pct}%)`;
                        }
                    }
                }
            }
        }
    });
}

// ──────────────────────────────────────────────
//  Render: Cost Table
// ──────────────────────────────────────────────
function renderCostTable(data) {
    const tbody = document.getElementById('cost-table-body');
    const footer = document.getElementById('cost-table-footer');
    const badge = document.getElementById('table-count');
    const services = data.costsByService;

    if (!services || services.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading-cell">No cost data available for this period.</td></tr>';
        footer.style.display = 'none';
        return;
    }

    const maxCost = Math.max(...services.map(s => s.cost));

    badge.textContent = `${services.length} service${services.length !== 1 ? 's' : ''}`;

    const rows = services.map((item, index) => {
        const sharePercent = maxCost > 0 ? ((item.cost / maxCost) * 100).toFixed(1) : 0;
        const grossCost = item.grossCost !== undefined ? item.grossCost : item.cost;
        const credits = item.credits !== undefined ? item.credits : 0;

        return `
            <tr>
                <td class="rank-cell">${index + 1}</td>
                <td class="service-cell">${item.service}</td>
                <td class="cost-cell">$${grossCost.toFixed(2)}</td>
                <td class="credits-cell">${credits < 0 ? '-$' + Math.abs(credits).toFixed(2) : '$0.00'}</td>
                <td class="net-cell">$${item.cost.toFixed(2)}</td>
                <td class="bar-cell">
                    <div class="share-bar-track">
                        <div class="share-bar-fill" style="width: ${sharePercent}%"></div>
                    </div>
                </td>
            </tr>
        `;
    }).join('');

    tbody.innerHTML = rows;

    // Footer totals
    const totalGross = data.totalGrossCost || data.totalCost;
    const totalCredits = data.totalCredits || 0;

    document.getElementById('footer-gross').textContent = `$${totalGross.toFixed(2)}`;
    document.getElementById('footer-credits').textContent =
        totalCredits < 0 ? `-$${Math.abs(totalCredits).toFixed(2)}` : '$0.00';
    document.getElementById('footer-net').textContent = `$${data.totalCost.toFixed(2)}`;
    footer.style.display = '';
}

// ──────────────────────────────────────────────
//  Render: Error State
// ──────────────────────────────────────────────
function renderError(message) {
    const tbody = document.getElementById('cost-table-body');
    tbody.innerHTML = `
        <tr>
            <td colspan="6">
                <div class="error-state">
                    <h3>Failed to Load Cost Data</h3>
                    <p>There was an error communicating with the backend API.
                       Please ensure the CI/CD pipeline has configured the API endpoint correctly.</p>
                    <div class="error-detail">${message}</div>
                </div>
            </td>
        </tr>
    `;
    document.getElementById('cost-table-footer').style.display = 'none';
}

// ──────────────────────────────────────────────
//  Utilities
// ──────────────────────────────────────────────
function updateTimestamp(text) {
    document.getElementById('last-updated').textContent = text;
}

function formatDate(dateStr) {
    const d = new Date(dateStr + 'T00:00:00Z');
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function truncateLabel(label, maxLen) {
    return label.length > maxLen ? label.substring(0, maxLen - 1) + '…' : label;
}