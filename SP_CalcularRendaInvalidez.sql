CREATE TABLE Participantes (
    ParticipanteID INT PRIMARY KEY,
    Nome NVARCHAR(100),
    DataNascimento DATE,
    Genero CHAR(1), -- 'M' para Masculino, 'F' para Feminino
    DataEntrada DATE -- Data de entrada no plano
);

CREATE TABLE Contribuicoes (
    ContribuicaoID INT PRIMARY KEY IDENTITY(1,1),
    ParticipanteID INT,
    DataContribuicao DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE FatoresAtuariais (
    FatorID INT PRIMARY KEY IDENTITY(1,1),
    Idade INT,
    Genero CHAR(1),
    TipoBeneficio NVARCHAR(50), -- Por exemplo, 'Invalidez'
    Fator DECIMAL(10, 6)
);

CREATE TABLE RendaInvalidez (
    RendaInvalidezID INT PRIMARY KEY IDENTITY(1,1),
    ParticipanteID INT,
    DataCalculo DATE,
    ValorMensal DECIMAL(18, 2),
    SaldoAcumulado DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

-----

CREATE PROCEDURE CalcularRendaInvalidez
    @ParticipanteID INT,
    @ValorMensal DECIMAL(18, 2) OUTPUT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE @SaldoAcumulado DECIMAL(18, 2);
    DECLARE @Idade INT;
    DECLARE @DataNascimento DATE;
    DECLARE @DataAtual DATE = GETDATE();
    DECLARE @FatorAtuarial DECIMAL(10, 6);
    DECLARE @Genero CHAR(1);
    
    -- Obter dados do participante
    SELECT 
        @DataNascimento = DataNascimento,
        @Genero = Genero
    FROM 
        Participantes
    WHERE 
        ParticipanteID = @ParticipanteID;

    -- Calcular a idade atual do participante
    SET @Idade = DATEDIFF(YEAR, @DataNascimento, @DataAtual) - 
                 CASE WHEN MONTH(@DataAtual) < MONTH(@DataNascimento) OR 
                           (MONTH(@DataAtual) = MONTH(@DataNascimento) AND DAY(@DataAtual) < DAY(@DataNascimento)) 
                      THEN 1 
                      ELSE 0 
                 END;

    -- Calcular o saldo acumulado (soma de contribuições)
    SELECT 
        @SaldoAcumulado = COALESCE(SUM(Valor), 0)
    FROM 
        Contribuicoes
    WHERE 
        ParticipanteID = @ParticipanteID;

    -- Obter o fator atuarial específico para invalidez
    SELECT 
        @FatorAtuarial = Fator
    FROM 
        FatoresAtuariais
    WHERE 
        Idade = @Idade AND Genero = @Genero AND TipoBeneficio = 'Invalidez';

    -- Calcular o valor mensal da renda por invalidez
    IF @FatorAtuarial IS NOT NULL AND @SaldoAcumulado > 0
    BEGIN
        SET @ValorMensal = @SaldoAcumulado * @FatorAtuarial;
    END
    ELSE
    BEGIN
        SET @ValorMensal = 0; -- Caso não haja fator atuarial ou saldo acumulado
    END

    -- Registrar o cálculo de renda por invalidez
    INSERT INTO RendaInvalidez (ParticipanteID, DataCalculo, ValorMensal, SaldoAcumulado)
    VALUES (@ParticipanteID, @DataAtual, @ValorMensal, @SaldoAcumulado);
END;

-------

DECLARE @ValorMensal DECIMAL(18, 2);

EXEC CalcularRendaInvalidez @ParticipanteID = 1, @ValorMensal = @ValorMensal OUTPUT;

SELECT @ValorMensal AS ValorMensalInvalidez;

------

-- Inserir dados na tabela Participantes (fictícios)
INSERT INTO Participantes (Nome, DataNascimento, Genero, DataEntrada) VALUES
('João Silva', '1980-01-01', 'M', '2000-01-01'),
('Maria Oliveira', '1975-05-10', 'F', '1995-01-01');

-- Inserir dados na tabela Contribuicoes
INSERT INTO Contribuicoes (ParticipanteID, DataContribuicao, Valor) VALUES
(1, '2022-01-01', 500.00),
(1, '2022-02-01', 500.00),
(1, '2022-03-01', 500.00),
(2, '2022-01-01', 700.00),
(2, '2022-02-01', 700.00),
(2, '2022-03-01', 700.00);

-- Inserir dados na tabela FatoresAtuariais
INSERT INTO FatoresAtuariais (Idade, Genero, TipoBeneficio, Fator) VALUES
(42, 'M', 'Invalidez', 0.005),
(47, 'F', 'Invalidez', 0.006);