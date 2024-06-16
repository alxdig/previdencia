CREATE TABLE Participantes (
    ParticipanteID INT PRIMARY KEY,
    Nome NVARCHAR(100),
    DataNascimento DATE,
    Genero CHAR(1), -- 'M' para Masculino, 'F' para Feminino
    DataEntrada DATE -- Data de entrada no plano
);

CREATE TABLE Contribuicoes (
    ContribuicaoID INT PRIMARY KEY,
    ParticipanteID INT,
    DataContribuicao DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE Salarios (
    SalarioID INT PRIMARY KEY,
    ParticipanteID INT,
    DataSalario DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE Resgates (
    ResgateID INT PRIMARY KEY,
    ParticipanteID INT,
    DataResgate DATE,
    Valor DECIMAL(18, 2),
    IRRetido DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE AliquotasIR (
    FaixaID INT PRIMARY KEY,
    LimiteInferior DECIMAL(18, 2),
    LimiteSuperior DECIMAL(18, 2),
    Aliquota DECIMAL(5, 2),
    ParcelaDeduzir DECIMAL(18, 2) -- Renomeada para maior clareza
);

-----

CREATE PROCEDURE CalcularResgateComIR_progressivo
    @ParticipanteID INT,
    @ValorResgate DECIMAL(18, 2),
    @ValorResgateLiquido DECIMAL(18, 2) OUTPUT,
    @IRRetido DECIMAL(18, 2) OUTPUT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE @IRTotal DECIMAL(18, 2) = 0;
    DECLARE @ValorRestante DECIMAL(18, 2) = @ValorResgate;
    DECLARE @ValorFaixa DECIMAL(18, 2);
    DECLARE @Aliquota DECIMAL(5, 2);
    DECLARE @ParcelaDeduzir DECIMAL(18, 2);
    DECLARE @LimiteInferior DECIMAL(18, 2);
    DECLARE @LimiteSuperior DECIMAL(18, 2);

    -- Calcular o IR de acordo com as alíquotas progressivas
    DECLARE aliquota_cursor CURSOR FOR
    SELECT 
        LimiteInferior,
        LimiteSuperior,
        Aliquota,
        ParcelaDeduzir
    FROM 
        AliquotasIR
    ORDER BY 
        LimiteInferior;

    OPEN aliquota_cursor;

    FETCH NEXT FROM aliquota_cursor INTO @LimiteInferior, @LimiteSuperior, @Aliquota, @ParcelaDeduzir;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @ValorRestante > 0
        BEGIN
            IF @ValorRestante > @LimiteSuperior - @LimiteInferior
            BEGIN
                SET @ValorFaixa = @LimiteSuperior - @LimiteInferior;
            END
            ELSE
            BEGIN
                SET @ValorFaixa = @ValorRestante;
            END

            SET @IRTotal = @IRTotal + (@ValorFaixa * @Aliquota / 100) - @ParcelaDeduzir;

            SET @ValorRestante = @ValorRestante - @ValorFaixa;
        END

        FETCH NEXT FROM aliquota_cursor INTO @LimiteInferior, @LimiteSuperior, @Aliquota, @ParcelaDeduzir;
    END

    CLOSE aliquota_cursor;
    DEALLOCATE aliquota_cursor;

    -- Definir o valor do IR retido e o valor líquido do resgate
    SET @IRRetido = @IRTotal;
    SET @ValorResgateLiquido = @ValorResgate - @IRRetido;

    -- Registrar o resgate
    INSERT INTO Resgates (ParticipanteID, DataResgate, Valor, IRRetido)
    VALUES (@ParticipanteID, GETDATE(), @ValorResgate, @IRRetido);
END;

----

INSERT INTO AliquotasIR (FaixaID, LimiteInferior, LimiteSuperior, Aliquota, ParcelaDeduzir) VALUES
(1, 0.00, 1903.98, 0.00, 0.00),
(2, 1903.99, 2826.65, 7.50, 142.80),
(3, 2826.66, 3751.05, 15.00, 354.80),
(4, 3751.06, 4664.68, 22.50, 636.13),
(5, 4664.69, 9999999.99, 27.50, 869.36);

-----

DECLARE @ValorResgateLiquido DECIMAL(18, 2);
DECLARE @IRRetido DECIMAL(18, 2);

EXEC CalcularResgateComIR_progressivo @ParticipanteID = 1, @ValorResgate = 5000.00, @ValorResgateLiquido = @ValorResgateLiquido OUTPUT, @IRRetido = @IRRetido OUTPUT;

SELECT @ValorResgateLiquido AS ValorResgateLiquido, @IRRetido AS IRRetido;