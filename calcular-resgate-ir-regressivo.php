<?php
// Função para calcular o imposto de renda previdenciária
function calcularImpostoPrevidencia($dataResgate, $valorResgate, $aportes) {
    // Inicialização de variáveis
    $impostoTotal = 0;
    $valorResgateRestante = $valorResgate;
    $detalhamentoAportes = [];

    // Definição das alíquotas
    $aliquotas = [
        2 => 0.35,
        4 => 0.30,
        6 => 0.25,
        8 => 0.20,
        10 => 0.15,
    ];

    // Ordenando aportes do mais antigo para o mais recente (por data)
    usort($aportes, function($a, $b) {
        return strtotime($a['data']) - strtotime($b['data']);
    });

    // Loop através dos aportes para cálculo do imposto
    foreach ($aportes as $aporte) {
        $dataAporte = $aporte['data'];
        $valorAporte = $aporte['valor'];

        // Calculando tempo de acumulação em anos
        $tempoAcumulacao = (strtotime($dataResgate) - strtotime($dataAporte)) / (60 * 60 * 24 * 365);

        // Determinando a alíquota com base no tempo de acumulação
        foreach ($aliquotas as $limite => $aliquota) {
            if ($tempoAcumulacao <= $limite) {
                $aliquotaAplicada = $aliquota;
                break;
            }
        }
        // Se o tempo de acumulação for maior que 10 anos, aplica a alíquota máxima
        if (!isset($aliquotaAplicada)) {
            $aliquotaAplicada = 0.10;
        }

        // Calculando imposto para o aporte atual
        if ($valorResgateRestante >= $valorAporte) {
            $impostoAporte = $valorAporte * $aliquotaAplicada;
            $valorResgateRestante -= $valorAporte;
        } else {
            $impostoAporte = $valorResgateRestante * $aliquotaAplicada;
            $valorResgateRestante = 0;
        }

        // Somando ao imposto total
        $impostoTotal += $impostoAporte;

        // Armazenando detalhes do aporte para retorno
        $detalhamentoAportes[] = [
            'data' => $dataAporte,
            'valor' => $valorAporte,
            'tempoAcumulacao' => $tempoAcumulacao,
            'aliquota' => $aliquotaAplicada,
            'impostoCalculado' => $impostoAporte
        ];

        // Se já resgatou o valor desejado, interrompe o loop
        if ($valorResgateRestante <= 0) {
            break;
        }
    }

    // Retornando resultados
    return [
        'impostoTotalDevido' => $impostoTotal,
        'detalhamentoAportes' => $detalhamentoAportes
    ];
}

// Verifica se a requisição é um POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Obtém os dados da requisição (JSON)
    $dadosRequisicao = json_decode(file_get_contents('php://input'), true);

    // Verifica se todos os parâmetros necessários estão presentes na requisição
    if (isset($dadosRequisicao['dataResgate'], $dadosRequisicao['valorResgate'], $dadosRequisicao['aportes'])) {
        // Chama a função para calcular o imposto de renda previdenciária
        $resultado = calcularImpostoPrevidencia($dadosRequisicao['dataResgate'], $dadosRequisicao['valorResgate'], $dadosRequisicao['aportes']);

        // Define o cabeçalho da resposta como JSON
        header('Content-Type: application/json');

        // Retorna o resultado como JSON
        echo json_encode($resultado);
    } else {
        // Se algum parâmetro estiver faltando, retorna erro 400 (Bad Request)
        http_response_code(400);
        echo json_encode(['erro' => 'Parâmetros inválidos']);
    }
} else {
    // Se a requisição não for um POST, retorna erro 405 (Method Not Allowed)
    http_response_code(405);
    echo json_encode(['erro' => 'Método não permitido']);
}