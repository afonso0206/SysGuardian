<?php

require_once __DIR__ . '/report-source.php';

const SYSGUARDIAN_TCPDF = '/usr/share/php/tcpdf/tcpdf.php';

function report_error(int $status): void
{
    http_response_code($status);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Não foi possível gerar o relatório.';
    exit;
}

if (!is_file(SYSGUARDIAN_TCPDF) || !is_readable(SYSGUARDIAN_TCPDF)) {
    report_error(500);
}

require_once SYSGUARDIAN_TCPDF;

if (!class_exists('TCPDF')) {
    report_error(500);
}

$reportFile = sysguardian_latest_report();

if ($reportFile === null) {
    report_error(404);
}

$reportContents = file_get_contents($reportFile);

if ($reportContents === false) {
    report_error(500);
}

try {
    $report = json_decode($reportContents, true, 512, JSON_THROW_ON_ERROR);
} catch (JsonException $error) {
    report_error(500);
}

if (!is_array($report) ||
    !isset($report['metadata']) || !is_array($report['metadata']) ||
    !isset($report['printers']) || !is_array($report['printers']) ||
    !isset($report['printers']['devices']) || !is_array($report['printers']['devices'])) {
    report_error(500);
}

function pdf_escape(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE | ENT_HTML5, 'UTF-8');
}

function available_value(mixed $value): ?string
{
    if ($value === null || is_array($value) || is_object($value) || is_bool($value)) {
        return null;
    }

    if ((is_int($value) || is_float($value)) && $value === -1) {
        return null;
    }

    $text = trim((string) $value);

    if ($text === '' || strtoupper($text) === 'N/A' || $text === '-1') {
        return null;
    }

    return $text;
}

function display_value(mixed $value): string
{
    return pdf_escape(available_value($value) ?? 'N/D');
}

function valid_nonnegative_number(mixed $value): int|float|null
{
    return (is_int($value) || is_float($value)) && is_finite((float) $value) && $value >= 0
        ? $value
        : null;
}

function valid_percent(mixed $value): int|float|null
{
    $number = valid_nonnegative_number($value);

    return $number !== null && $number <= 100 ? $number : null;
}

function display_number(mixed $value): string
{
    $number = valid_nonnegative_number($value);

    if ($number === null) {
        return 'N/D';
    }

    $decimals = is_float($number) && floor($number) !== $number ? 2 : 0;
    return pdf_escape(number_format($number, $decimals, ',', '.'));
}

function display_percent(mixed $value): string
{
    $percent = valid_percent($value);
    return $percent === null ? 'N/D' : pdf_escape(number_format($percent, 0, ',', '.') . '%');
}

function display_errors(mixed $errors): string
{
    if (!is_array($errors)) {
        return 'N/D';
    }

    $values = [];

    foreach ($errors as $error) {
        $value = available_value($error);
        if ($value !== null) {
            $values[] = $value;
        }
    }

    return $values ? pdf_escape(implode('; ', $values)) : 'N/D';
}

function display_status(mixed $status): string
{
    $value = strtolower(available_value($status) ?? '');

    return match ($value) {
        'online' => 'Online',
        'offline' => 'Offline',
        'warning' => 'Alerta',
        default => 'N/D'
    };
}

function display_date(mixed $value): string
{
    $text = available_value($value);

    if ($text === null) {
        return 'N/D';
    }

    try {
        return pdf_escape((new DateTimeImmutable($text))->format('d/m/Y H:i:s'));
    } catch (Exception $error) {
        return pdf_escape($text);
    }
}

function summary_count(mixed $value): ?int
{
    return is_int($value) && $value >= 0 ? $value : null;
}

class PrintersReportPdf extends TCPDF
{
    private string $generatedAt;
    private string $logoFile;

    public function configureHeader(string $generatedAt, string $logoFile): void
    {
        $this->generatedAt = $generatedAt;
        $this->logoFile = $logoFile;
    }

    public function Header(): void
    {
        if (is_readable($this->logoFile)) {
            $this->ImageSVG($this->logoFile, 15, 7, 10, 10);
        }

        $this->SetFont('dejavusans', 'B', 10);
        $this->SetXY(28, 8);
        $this->Cell(90, 5, 'SysGuardian', 0, 0, 'L');
        $this->SetFont('dejavusans', '', 8);
        $this->SetXY(118, 8);
        $this->Cell(77, 5, 'UEMG — Unidade ESMU', 0, 0, 'R');
        $this->SetDrawColor(59, 130, 246);
        $this->Line(15, 20, 195, 20);
    }

    public function Footer(): void
    {
        $this->SetY(-16);
        $this->SetDrawColor(203, 213, 225);
        $this->Line(15, $this->GetY(), 195, $this->GetY());
        $this->Ln(2);
        $this->SetFont('dejavusans', '', 7);
        $this->Cell(112, 4, 'SysGuardian — Relatório Gerencial de Impressoras — ESMU/UEMG', 0, 0, 'L');
        $this->Cell(43, 4, $this->generatedAt, 0, 0, 'C');
        $this->Cell(25, 4, 'Página ' . $this->getAliasNumPage() . ' de ' . $this->getAliasNbPages(), 0, 0, 'R');
    }
}

$metadata = $report['metadata'];
$printers = $report['printers'];
$devices = array_values(array_filter($printers['devices'], 'is_array'));
$summary = isset($printers['summary']) && is_array($printers['summary']) ? $printers['summary'] : [];
$generatedDate = new DateTimeImmutable('now', new DateTimeZone('America/Sao_Paulo'));
$generatedAt = $generatedDate->format('d/m/Y H:i:s');

$calculatedOnline = count(array_filter($devices, fn($device) => ($device['status'] ?? null) === 'online'));
$calculatedOffline = count(array_filter($devices, fn($device) => ($device['status'] ?? null) === 'offline'));
$calculatedWarnings = count(array_filter($devices, function($device) {
    if (isset($device['errors']) && is_array($device['errors']) && count($device['errors']) > 0) {
        return true;
    }

    foreach (['black', 'cyan', 'magenta', 'yellow'] as $color) {
        $percent = valid_percent($device['toner'][$color] ?? null);
        if ($percent !== null && $percent <= 10) {
            return true;
        }
    }

    return false;
}));

$summaryValues = [
    'Total' => summary_count($summary['total'] ?? null) ?? count($devices),
    'Online' => summary_count($summary['online'] ?? null) ?? $calculatedOnline,
    'Offline' => summary_count($summary['offline'] ?? null) ?? $calculatedOffline,
    'Alertas' => summary_count($summary['warnings'] ?? null) ?? $calculatedWarnings
];

$pdf = new PrintersReportPdf(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
$pdf->configureHeader($generatedAt, dirname(__DIR__) . '/assets/logo.svg');
$pdf->SetCreator('SysGuardian');
$pdf->SetAuthor('GTIC/UEMG — ESMU');
$pdf->SetTitle('Relatório Gerencial de Impressoras');
$pdf->SetSubject('Conferência mensal de impressoras');
$pdf->SetMargins(15, 27, 15);
$pdf->SetHeaderMargin(6);
$pdf->SetFooterMargin(12);
$pdf->SetAutoPageBreak(true, 22);
$pdf->setFontSubsetting(true);
$pdf->SetFont('dejavusans', '', 9);
$pdf->AddPage('P', 'A4');

$styles = '<style>
    h1 { color: #0f172a; font-size: 18pt; text-align: center; }
    h2 { color: #1e3a8a; font-size: 12pt; }
    h3 { color: #0f172a; font-size: 10pt; }
    table { border-collapse: collapse; }
    th { background-color: #dbeafe; color: #0f172a; font-weight: bold; }
    td, th { border: 1px solid #cbd5e1; padding: 4px; }
    .label { background-color: #f1f5f9; font-weight: bold; width: 28%; }
    .summary-label { color: #475569; font-size: 8pt; text-align: center; }
    .summary-value { color: #0f172a; font-size: 15pt; font-weight: bold; text-align: center; }
    .muted { color: #475569; }
</style>';

$intro = $styles
    . '<h1>Relatório Gerencial de Impressoras</h1>'
    . '<table cellpadding="5">'
    . '<tr><td class="label">Instituição</td><td>UEMG</td><td class="label">Unidade</td><td>ESMU</td></tr>'
    . '<tr><td class="label">Host</td><td>' . display_value($metadata['hostname'] ?? null) . '</td>'
    . '<td class="label">Competência</td><td>____/______</td></tr>'
    . '<tr><td class="label">Data/hora da auditoria</td><td>' . display_value($metadata['date'] ?? null) . '</td>'
    . '<td class="label">Data/hora da geração</td><td>' . pdf_escape($generatedAt) . '</td></tr>'
    . '</table><br><h2>Resumo gerencial</h2><table cellpadding="6"><tr>';

foreach ($summaryValues as $label => $value) {
    $intro .= '<td><div class="summary-label">' . pdf_escape($label) . '</div>'
        . '<div class="summary-value">' . pdf_escape($value) . '</div></td>';
}

$intro .= '</tr></table><br><h2>Conferência contratual</h2>'
    . '<table cellpadding="4"><thead><tr>'
    . '<th width="14%">Impressora</th><th width="24%">Modelo</th>'
    . '<th width="19%">Número de série</th><th width="17%">IP</th>'
    . '<th width="16%">Total de páginas</th><th width="10%">Status</th>'
    . '</tr></thead><tbody>';

foreach ($devices as $device) {
    $intro .= '<tr>'
        . '<td width="14%">' . display_value($device['name'] ?? null) . '</td>'
        . '<td width="24%">' . display_value($device['model'] ?? null) . '</td>'
        . '<td width="19%">' . display_value($device['serial'] ?? null) . '</td>'
        . '<td width="17%">' . display_value($device['ip'] ?? null) . '</td>'
        . '<td width="16%" align="right">' . display_number($device['total_pages'] ?? null) . '</td>'
        . '<td width="10%">' . display_status($device['status'] ?? null) . '</td>'
        . '</tr>';
}

$intro .= '</tbody></table>';
$pdf->writeHTML($intro, true, false, true, false, '');

foreach ($devices as $deviceIndex => $device) {
    $pdf->AddPage('P', 'A4');

    if ($deviceIndex === 0) {
        $pdf->writeHTML($styles . '<h2>Detalhamento das impressoras</h2>', true, false, true, false, '');
    }

    $toner = isset($device['toner']) && is_array($device['toner']) ? $device['toner'] : [];
    $paper = isset($device['paper']) && is_array($device['paper']) ? $device['paper'] : [];
    $drum = isset($device['drum']) && is_array($device['drum']) ? $device['drum'] : [];
    $colorToners = [];

    foreach (['cyan' => 'Cyan', 'magenta' => 'Magenta', 'yellow' => 'Yellow'] as $key => $label) {
        if (valid_percent($toner[$key] ?? null) !== null) {
            $colorToners[$label] = display_percent($toner[$key]);
        }
    }

    $rows = [
        'Nome' => display_value($device['name'] ?? null),
        'IP' => display_value($device['ip'] ?? null),
        'Status' => display_status($device['status'] ?? null),
        'Modelo' => display_value($device['model'] ?? null),
        'Firmware' => display_value($device['firmware'] ?? null),
        'Número de série' => display_value($device['serial'] ?? null),
        'MAC' => display_value($device['mac'] ?? null),
        'Localização' => display_value($device['location'] ?? null),
        'Descrição' => display_value($device['description'] ?? null),
        'Erros' => display_errors($device['errors'] ?? null),
        'Tempo de resposta' => valid_nonnegative_number($device['response_ms'] ?? null) !== null
            ? display_number($device['response_ms']) . ' ms'
            : 'N/D',
        'Uptime' => display_value($device['uptime'] ?? null),
        'Total de páginas' => display_number($device['total_pages'] ?? null),
        'Toner preto' => display_percent($toner['black'] ?? null)
    ];

    foreach ($colorToners as $label => $value) {
        $rows['Toner ' . $label] = $value;
    }

    $rows['Papel'] = display_percent($paper['percent'] ?? null);
    $rows['Drum'] = display_percent($drum['percent'] ?? null);
    $rows['Última coleta'] = display_date($device['last_collection'] ?? null);

    $deviceHtml = '<h3>' . display_value($device['name'] ?? null) . '</h3><table cellpadding="4">';

    foreach ($rows as $label => $value) {
        $deviceHtml .= '<tr><td class="label">' . pdf_escape($label) . '</td><td>' . $value . '</td></tr>';
    }

    $deviceHtml .= '</table><br>';
    $pdf->writeHTML($styles . $deviceHtml, true, false, true, false, '');
}

if ($pdf->GetY() > 205) {
    $pdf->AddPage('P', 'A4');
}

$responsible = $styles
    . '<h2>RESPONSÁVEL — TI DA UNIDADE</h2>'
    . '<p><strong>Unidade:</strong> ESMU</p><br>'
    . '<p><strong>Nome:</strong> __________________________________________</p><br>'
    . '<p><strong>Assinatura:</strong> _____________________________________</p><br>'
    . '<p><strong>Data:</strong> ____/____/________</p>';
$pdf->writeHTML($responsible, true, false, true, false, '');

$reportId = $generatedDate->format('Ymd_His');
if (preg_match('/^report_(\d{8}_\d{6})\.json$/', basename($reportFile), $matches)) {
    $reportId = $matches[1];
}

$pdfName = 'sysguardian-impressoras-esmu-' . $reportId . '.pdf';
$pdf->Output($pdfName, 'I');
