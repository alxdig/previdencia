CREATE PROCEDURE CalcularImpostoPrevidencia
    @DataResgate DATE,
    @ValorResgate DECIMAL(10, 2)
AS
BEGIN
    -- Tabela temporária para armazenar os resultados de cada aporte
    CREATE TABLE #DetalhamentoAportes (
        Data DATE,
        Valor DECIMAL(10, 2),
        TempoAcumulacao DECIMAL(10, 2),
        Aliquota DECIMAL(5, 2),
        ImpostoCalculado DECIMAL(10, 2)
    );

    -- Variáveis para cálculo
    DECLARE @ImpostoTotal DECIMAL(10, 2);
    DECLARE @ImpostoAporte DECIMAL(10, 2);
    DECLARE @TempoAcumulacao DECIMAL(10, 2);
    DECLARE @Alquota DECIMAL(5, 2);
    DECLARE @ValorResgateRestante DECIMAL(10, 2);
    DECLARE @ValorAporte DECIMAL(10, 2);
    DECLARE @DataAporte DATE;

    -- Aportes fictícios para exemplo
    DECLARE @Aportes TABLE (
        Data DATE,
        Valor DECIMAL(10, 2)
    );

    -- Inserindo dados de exemplo (substituir pelos dados reais)
    INSERT INTO @Aportes (Data, Valor)
    VALUES
        ('2015-01-01', 1000),
        ('2016-03-15', 1500),
        ('2017-07-20', 800),
        ('2018-11-10', 1200),
        ('2019-05-30', 2000);

    -- Inicializando variáveis
    SET @ImpostoTotal = 0;
    SET @ValorResgateRestante = @ValorResgate;

    -- Loop através dos aportes para cálculo do imposto
    DECLARE cur CURSOR FOR
    SELECT Data, Valor
    FROM @Aportes
    ORDER BY Data ASC; -- Ordenando aportes do mais antigo para o mais recente

    OPEN cur;
    FETCH NEXT FROM cur INTO @DataAporte, @ValorAporte;

    WHILE @@FETCH_STATUS = 0 AND @ValorResgateRestante > 0
    BEGIN
        -- Calculando tempo de acumulação em anos
        SET @TempoAcumulacao = DATEDIFF(MONTH, @DataAporte, @DataResgate) / 12.0;

        -- Determinando alíquota com base no tempo de acumulação
        IF @TempoAcumulacao <= 2
            SET @Alquota = 0.35;
        ELSE IF @TempoAcumulacao <= 4
            SET @Alquota = 0.30;
        ELSE IF @TempoAcumulacao <= 6
            SET @Alquota = 0.25;
        ELSE IF @TempoAcumulacao <= 8
            SET @Alquota = 0.20;
        ELSE IF @TempoAcumulacao <= 10
            SET @Alquota = 0.15;
        ELSE
            SET @Alquota = 0.10;

        -- Calculando imposto para o aporte atual
        SET @ImpostoAporte = @ValorAporte * @Alquota;

        -- Verificando quanto do aporte vamos resgatar
        IF @ValorResgateRestante >= @ValorAporte
        BEGIN
            -- Resgatamos o valor total do aporte
            SET @ValorResgateRestante = @ValorResgateRestante - @ValorAporte;
        END
        ELSE
        BEGIN
            -- Resgatamos apenas parte do aporte
            SET @ImpostoAporte = @ValorResgateRestante * @Alquota;
            SET @ValorResgateRestante = 0; -- Nada mais a resgatar
        END;

        -- Somando ao imposto total
        SET @ImpostoTotal = @ImpostoTotal + @ImpostoAporte;

        -- Inserindo detalhes do aporte na tabela temporária
        INSERT INTO #DetalhamentoAportes (Data, Valor, TempoAcumulacao, Aliquota, ImpostoCalculado)
        VALUES (@DataAporte, @ValorAporte, @TempoAcumulacao, @Alquota, @ImpostoAporte);

        FETCH NEXT FROM cur INTO @DataAporte, @ValorAporte;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    -- Retornando resultados
    SELECT
        ImpostoTotalDevido = @ImpostoTotal,
        DetalhamentoAportes.*
    FROM #DetalhamentoAportes DetalhamentoAportes;

    -- Removendo tabela temporária
    DROP TABLE #DetalhamentoAportes;
END;