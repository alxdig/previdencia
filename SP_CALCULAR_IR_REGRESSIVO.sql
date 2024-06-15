CREATE TABLE Aportes (
    Id INT PRIMARY KEY,
    Data DATE,
    Valor DECIMAL(18, 2),
    TipoAporteId INT
);

CREATE TABLE TiposAporte (
    Id INT PRIMARY KEY,
    Descricao NVARCHAR(100),
    PercentualMaximoResgate DECIMAL(5, 2)  -- Percentual em formato decimal, ex: 0.75 para 75%
);


CREATE PROCEDURE CalcularImpostoPrevidencia
    @DataResgate DATE,
    @ValorResgate DECIMAL(18, 2)
AS
BEGIN
    DECLARE @ImpostoTotal DECIMAL(18, 2) = 0
    DECLARE @ValorResgateRestante DECIMAL(18, 2) = @ValorResgate

    -- Temporária para armazenar os detalhes dos aportes
    CREATE TABLE #DetalhamentoAportes (
        Data DATE,
        Valor DECIMAL(18, 2),
        PercentualMaximoResgate DECIMAL(5, 2),
        TempoAcumulacao DECIMAL(10, 2),
        Aliquota DECIMAL(5, 2),
        ValorResgate DECIMAL(18, 2),
        ImpostoCalculado DECIMAL(18, 2)
    )

    -- Definição das alíquotas
    DECLARE @Aliquotas TABLE (Limite INT, Aliquota DECIMAL(5, 2))
    INSERT INTO @Aliquotas VALUES (2, 0.35), (4, 0.30), (6, 0.25), (8, 0.20), (10, 0.15), (NULL, 0.10)

    -- Cursor para iterar pelos aportes ordenados por data
    DECLARE AportesCursor CURSOR FOR
    SELECT a.Data, a.Valor, ta.PercentualMaximoResgate
    FROM Aportes a
    JOIN TiposAporte ta ON a.TipoAporteId = ta.Id
    ORDER BY a.Data

    OPEN AportesCursor

    DECLARE @DataAporte DATE, @ValorAporte DECIMAL(18, 2), @PercentualMaximoResgate DECIMAL(5, 2)
    FETCH NEXT FROM AportesCursor INTO @DataAporte, @ValorAporte, @PercentualMaximoResgate

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcula o tempo de acumulação em anos
        DECLARE @TempoAcumulacao DECIMAL(10, 2) = DATEDIFF(DAY, @DataAporte, @DataResgate) / 365.0

        -- Determina a alíquota com base no tempo de acumulação
        DECLARE @Aliquota DECIMAL(5, 2)
        SELECT TOP 1 @Aliquota = Aliquota
        FROM @Aliquotas
        WHERE @TempoAcumulacao <= ISNULL(Limite, @TempoAcumulacao)
        ORDER BY Limite

        -- Calcula o valor máximo que pode ser resgatado deste aporte
        DECLARE @ValorMaximoResgate DECIMAL(18, 2) = @ValorAporte * @PercentualMaximoResgate

        -- Determina o valor a ser resgatado deste aporte
        DECLARE @ValorResgateAporte DECIMAL(18, 2) = CASE 
                                                        WHEN @ValorResgateRestante >= @ValorMaximoResgate 
                                                        THEN @ValorMaximoResgate 
                                                        ELSE @ValorResgateRestante 
                                                     END

        -- Calcula o imposto para o aporte atual
        DECLARE @ImpostoAporte DECIMAL(18, 2) = @ValorResgateAporte * @Aliquota

        -- Subtrai o valor resgatado do valor restante
        SET @ValorResgateRestante = @ValorResgateRestante - @ValorResgateAporte

        -- Soma ao imposto total
        SET @ImpostoTotal = @ImpostoTotal + @ImpostoAporte

        -- Armazena detalhes do aporte na tabela temporária
        INSERT INTO #DetalhamentoAportes (Data, Valor, PercentualMaximoResgate, TempoAcumulacao, Aliquota, ValorResgate, ImpostoCalculado)
        VALUES (@DataAporte, @ValorAporte, @PercentualMaximoResgate, @TempoAcumulacao, @Aliquota, @ValorResgateAporte, @ImpostoAporte)

        -- Se já resgatou o valor desejado, interrompe o loop
        IF @ValorResgateRestante <= 0
            BREAK

        FETCH NEXT FROM AportesCursor INTO @DataAporte, @ValorAporte, @PercentualMaximoResgate
    END

    CLOSE AportesCursor
    DEALLOCATE AportesCursor

    -- Retorna os resultados
    SELECT @ImpostoTotal AS ImpostoTotalDevido
    SELECT * FROM #DetalhamentoAportes

    -- Limpa a tabela temporária
    DROP TABLE #DetalhamentoAportes
END