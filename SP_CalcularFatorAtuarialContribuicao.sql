CREATE TABLE Participantes (
    ParticipanteID INT PRIMARY KEY,
    Nome NVARCHAR(100),
    DataNascimento DATE,
    Genero CHAR(1) -- 'M' para Masculino, 'F' para Feminino
);

CREATE TABLE Contribuicoes (
    ContribuicaoID INT PRIMARY KEY,
    ParticipanteID INT,
    DataContribuicao DATE,
    Valor DECIMAL(18, 2),
    FOREIGN KEY (ParticipanteID) REFERENCES Participantes(ParticipanteID)
);

CREATE TABLE Beneficios (
    BeneficioID INT PRIMARY KEY,
    Descricao NVARCHAR(200)
);

CREATE TABLE FatoresAtuariais (
    FatorID INT PRIMARY KEY,
    Idade INT,
    Genero CHAR(1),
    TipoBeneficioID INT,
    Fator DECIMAL(10, 6),
    FOREIGN KEY (TipoBeneficioID) REFERENCES Beneficios(BeneficioID)
);

----

CREATE PROCEDURE CalcularFatorAtuarialContribuicao
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
    DECLARE @DataPrimeiraContrib DATE;
    DECLARE @TempoContribuicao INT;

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

    -- Obter a data da primeira contribuição
    SELECT 
        @DataPrimeiraContrib = MIN(DataContribuicao)
    FROM 
        Contribuicoes
    WHERE 
        ParticipanteID = @ParticipanteID;

    -- Calcular o tempo de contribuição em anos
    SET @TempoContribuicao = DATEDIFF(YEAR, @DataPrimeiraContrib, @DataAtual);

    -- Obter o fator atuarial considerando idade, gênero e tipo de benefício
    SELECT 
        @Fator = Fator
    FROM 
        FatoresAtuariais
    WHERE 
        Idade = @Idade AND Genero = @Genero AND TipoBeneficioID = @BeneficioID;

    -- Ajustar o fator atuarial com base no tempo de contribuição (exemplo simplificado)
    IF @TempoContribuicao < 10
    BEGIN
        SET @Fator = @Fator * 1.1; -- Aumenta o fator em 10% se o tempo de contribuição for menor que 10 anos
    END
    ELSE IF @TempoContribuicao >= 20
    BEGIN
        SET @Fator = @Fator * 0.9; -- Reduz o fator em 10% se o tempo de contribuição for 20 anos ou mais
    END

    -- Retornar o fator atuarial
    SET @FatorAtuarial = @Fator;
END;

-----

DECLARE @FatorAtuarial DECIMAL(10, 6);

EXEC CalcularFatorAtuarialContribuicao @ParticipanteID = 1, @BeneficioID = 1, @FatorAtuarial = @FatorAtuarial OUTPUT;

SELECT @FatorAtuarial AS FatorAtuarial;
