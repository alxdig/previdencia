CREATE TABLE Participantes (
    ParticipanteID INT PRIMARY KEY,
    Nome NVARCHAR(100),
    DataNascimento DATE,
    Genero CHAR(1) -- 'M' para Masculino, 'F' para Feminino
);

CREATE TABLE Beneficios (
    BeneficioID INT PRIMARY KEY,
    Descricao NVARCHAR(200)
);

CREATE TABLE FatoresAtuariais (
    FatorID INT PRIMARY KEY,
    Idade INT,
    Genero CHAR(1),
    Fator DECIMAL(10, 6)
);

-----

CREATE PROCEDURE CalcularFatorAtuarialSimples
    @ParticipanteID INT,
    @BeneficioID INT,
    @FatorAtuarial DECIMAL(10, 6) OUTPUT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE @Idade INT;
    DECLARE @Genero CHAR(1);
    DECLARE @DataNascimento DATE;
    DECLARE @DataAtual DATE = GETDATE();
    DECLARE @Fator DECIMAL(10, 6);

    -- Obter dados do participante
    SELECT 
        @DataNascimento = DataNascimento,
        @Genero = Genero
    FROM 
        Participantes
    WHERE 
        ParticipanteID = @ParticipanteID;

    -- Calcular a idade do participante
    SET @Idade = DATEDIFF(YEAR, @DataNascimento, @DataAtual) - 
                 CASE WHEN MONTH(@DataAtual) < MONTH(@DataNascimento) OR 
                           (MONTH(@DataAtual) = MONTH(@DataNascimento) AND DAY(@DataAtual) < DAY(@DataNascimento)) 
                      THEN 1 
                      ELSE 0 
                 END;

    -- Obter o fator atuarial
    SELECT 
        @Fator = Fator
    FROM 
        FatoresAtuariais
    WHERE 
        Idade = @Idade AND Genero = @Genero;

    -- Retornar o fator atuarial
    SET @FatorAtuarial = @Fator;
END;

------

DECLARE @FatorAtuarial DECIMAL(10, 6);

EXEC CalcularFatorAtuarial @ParticipanteID = 1, @BeneficioID = 1, @FatorAtuarial = @FatorAtuarial OUTPUT;

SELECT @FatorAtuarial AS FatorAtuarial;