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

-----

CREATE PROCEDURE CalcularPeculioPorMorte
    @ParticipanteID INT,
    @PeculioPorMorte DECIMAL(18, 2) OUTPUT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE @Idade INT;
    DECLARE @Genero CHAR(1);
    DECLARE @DataNascimento DATE;
    DECLARE @DataAtual DATE = GETDATE();
    DECLARE @DataEntrada DATE;
    DECLARE @TempoContribuicao INT;
    DECLARE @SalarioMedio DECIMAL(18, 2);
    DECLARE @Fator DECIMAL(10, 6);
    DECLARE @TipoBeneficioID INT = 1; -- Assume que o ID 1 é para Pecúlio por Morte

    -- Obter dados do participante
    SELECT 
        @DataNascimento = DataNascimento,
        @Genero = Genero,
        @DataEntrada = DataEntrada
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

    -- Calcular o tempo de contribuição em anos
    SET @TempoContribuicao = DATEDIFF(YEAR, @DataEntrada, @DataAtual);

    -- Calcular o salário médio dos últimos 3 anos
    SELECT 
        @SalarioMedio = AVG(Valor)
    FROM 
        Salarios
    WHERE 
        ParticipanteID = @ParticipanteID
        AND DataSalario >= DATEADD(YEAR, -3, @DataAtual);

    -- Obter o fator atuarial considerando idade, gênero e tipo de benefício
    SELECT 
        @Fator = Fator
    FROM 
        FatoresAtuariais
    WHERE 
        Idade = @Idade AND Genero = @Genero AND TipoBeneficioID = @TipoBeneficioID;

    -- Calcular o pecúlio por morte
    SET @PeculioPorMorte = @SalarioMedio * @Fator * @TempoContribuicao;

    -- Ajustar o pecúlio por morte com base em condições específicas (exemplo simplificado)
    IF @TempoContribuicao < 5
    BEGIN
        SET @PeculioPorMorte = @PeculioPorMorte * 0.8; -- Reduz em 20% se o tempo de contribuição for menor que 5 anos
    END

    -- Retornar o pecúlio por morte
    SET @PeculioPorMorte = ROUND(@PeculioPorMorte, 2); -- Arredondar para duas casas decimais
END;

----

DECLARE @PeculioPorMorte DECIMAL(18, 2);

EXEC CalcularPeculioPorMorte @ParticipanteID = 1, @PeculioPorMorte = @PeculioPorMorte OUTPUT;

SELECT @PeculioPorMorte AS PeculioPorMorte;