CREATE TABLE Participantes (
    ParticipanteID INT PRIMARY KEY,
    Nome NVARCHAR(100),
    DataNascimento DATE,
    Genero CHAR(1), -- 'M' para Masculino, 'F' para Feminino
    DataEntrada DATE, -- Data de entrada no plano
    IdadeApqqqosentadoria INT -- Idade planejada para aposentadoria
);

CREATE TABLE Contribuicoes (
    ContribuicaoID INT PRIMARY KEY,
    ParticipanteID INT,
    DataContribuicao DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE Rendimentos (
    RendimentoID INT PRIMARY KEY,
    ParticipanteID INT,
    DataRendimento DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE Aposentadorias (
    AposentadoriaID INT PRIMARY KEY,
    ParticipanteID INT,
    DataCalculo DATE,
    ValorMensal DECIMAL(18, 2),
    SaldoAcumulado DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

------

CREATE PROCEDURE CalcularAposentadoria
    @ParticipanteID INT,
    @ValorMensal DECIMAL(18, 2) OUTPUT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE @SaldoAcumulado DECIMAL(18, 2);
    DECLARE @IdadeAposentadoria INT;
    DECLARE @IdadeAtual INT;
    DECLARE @DataNascimento DATE;
    DECLARE @DataAtual DATE = GETDATE();
    DECLARE @ExpectativaVida INT = 85; -- Supondo uma expectativa de vida de 85 anos

    -- Obter dados do participante
    SELECT 
        @DataNascimento = DataNascimento,
        @IdadeAposentadoria = IdadeAposentadoria
    FROM 
        Participantes
    WHERE 
        ParticipanteID = @ParticipanteID;

    -- Calcular a idade atual do participante
    SET @IdadeAtual = DATEDIFF(YEAR, @DataNascimento, @DataAtual) - 
                      CASE WHEN MONTH(@DataAtual) < MONTH(@DataNascimento) OR 
                                (MONTH(@DataAtual) = MONTH(@DataNascimento) AND DAY(@DataAtual) < DAY(@DataNascimento)) 
                           THEN 1 
                           ELSE 0 
                      END;

    -- Calcular o saldo acumulado (soma de contribuições e rendimentos)
    SELECT 
        @SaldoAcumulado = COALESCE(SUM(Valor), 0)
    FROM (
        SELECT Valor FROM Contribuicoes WHERE ParticipanteID = @ParticipanteID
        UNION ALL
        SELECT Valor FROM Rendimentos WHERE ParticipanteID = @ParticipanteID
    ) AS SaldoTotal;

    -- Calcular o número de anos de aposentadoria
    DECLARE @AnosAposentadoria INT = @ExpectativaVida - @IdadeAposentadoria;

    -- Calcular o valor mensal da aposentadoria
    IF @AnosAposentadoria > 0
    BEGIN
        SET @ValorMensal = @SaldoAcumulado / (@AnosAposentadoria * 12); -- 12 meses por ano
    END
    ELSE
    BEGIN
        SET @ValorMensal = 0; -- Se a idade de aposentadoria for maior que a expectativa de vida
    END

    -- Registrar o cálculo de aposentadoria
    INSERT INTO Aposentadorias (ParticipanteID, DataCalculo, ValorMensal, SaldoAcumulado)
    VALUES (@ParticipanteID, @DataAtual, @ValorMensal, @SaldoAcumulado);
END;

-----

DECLARE @ValorMensal DECIMAL(18, 2);

EXEC CalcularAposentadoria @ParticipanteID = 1, @ValorMensal = @ValorMensal OUTPUT;

SELECT @ValorMensal AS ValorMensalAposentadoria;
