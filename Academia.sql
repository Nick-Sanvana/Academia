CREATE TABLE alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL,
    valor_mensal_base DECIMAL(10,2) NOT NULL CHECK (valor_mensal_base > 0)
);

CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    plano_id INT NOT NULL REFERENCES planos(id),
    nome VARCHAR(100) NOT NULL,
    sala VARCHAR(30) NOT NULL,
    capacidade_maxima INT NOT NULL CHECK (capacidade_maxima > 0),
    disponivel BOOLEAN DEFAULT TRUE
);

CREATE TABLE matriculas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id),
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Ativa'
    CHECK (status IN ('Ativa', 'Cancelada', 'Trancada'))
);

CREATE TABLE itens_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INT NOT NULL REFERENCES matriculas(id),
    modalidade_id INT NOT NULL REFERENCES modalidades(id),
    duracao_meses INT NOT NULL CHECK (duracao_meses > 0),
    valor_mensal_aplicado DECIMAL(10,2) NOT NULL CHECK (valor_mensal_aplicado > 0),
    taxa_adesao DECIMAL(10,2) DEFAULT 0.00 CHECK (taxa_adesao >= 0)
);

INSERT INTO planos (nome, valor_mensal_base) VALUES
('Elite Fitness', 250.00),
('Power Training', 160.00),
('Start Gym', 85.00);

INSERT INTO modalidades (plano_id, nome, sala, capacidade_maxima, disponivel) VALUES
(1, 'Treinamento Funcional', 'Arena 03', 20, TRUE),
(2, 'Pilates Completo', 'Studio 05', 12, TRUE),
(3, 'Musculacao Geral', 'Sala Central', 40, TRUE);

INSERT INTO alunos (nome, email, cpf, telefone) VALUES
('Lucas Ferreira', 'lucas@email.com', '44455566677', '11966660000'),
('Mariana Souza', 'mariana@email.com', '55566677788', '11955550000'),
('Pedro Oliveira', 'pedro@email.com', '66677788899', '11944440000');

INSERT INTO matriculas (aluno_id, status) VALUES
(1, 'Ativa'),
(1, 'Ativa'),
(2, 'Ativa'),
(3, 'Cancelada');

INSERT INTO itens_matricula
(matricula_id, modalidade_id, duracao_meses, valor_mensal_aplicado, taxa_adesao) VALUES
(1, 1, 6, 250.00, 60.00),
(2, 2, 4, 160.00, 40.00),
(3, 3, 12, 85.00, 0.00),
(4, 1, 2, 250.00, 60.00);


CREATE VIEW vw_modalidades_custo_estimado AS
SELECT
    m.nome AS modalidade,
    m.sala,
    p.nome AS plano,
    ROUND(p.valor_mensal_base * 1.10, 2) AS mensalidade_ajustada
FROM modalidades m
JOIN planos p ON m.plano_id = p.id
ORDER BY mensalidade_ajustada DESC;


CREATE VIEW vw_matriculas_ativas AS
SELECT
    a.nome AS nome_aluno,
    a.cpf,
    mod.nome AS modalidade,
    mod.sala,
    im.duracao_meses,
    mat.data_inicio
FROM matriculas mat
JOIN alunos a ON mat.aluno_id = a.id
JOIN itens_matricula im ON mat.id = im.matricula_id
JOIN modalidades mod ON im.modalidade_id = mod.id
WHERE mat.status = 'Ativa';


CREATE VIEW vw_alunos_vip AS
SELECT
    a.nome AS nome_aluno,
    COUNT(mat.id) AS quantidade_contratos,
    SUM((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) AS valor_total
FROM alunos a
JOIN matriculas mat ON a.id = mat.aluno_id
JOIN itens_matricula im ON mat.id = im.matricula_id
WHERE mat.status = 'Ativa'
GROUP BY a.id, a.nome
HAVING SUM((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) > 1000.00;


SELECT
    m.*,
    p.nome AS nome_plano,
    p.valor_mensal_base
FROM modalidades m
JOIN planos p ON m.plano_id = p.id
WHERE m.capacidade_maxima >= 15
AND p.valor_mensal_base > 100.00
AND m.disponivel = TRUE;


CREATE VIEW vw_faturamento_medio_plano AS
SELECT
    p.nome AS nome_plano,
    SUM((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) AS faturamento_total,
    ROUND(AVG(im.duracao_meses), 1) AS media_duracao
FROM itens_matricula im
JOIN matriculas mat ON im.matricula_id = mat.id
JOIN modalidades m ON im.modalidade_id = m.id
JOIN planos p ON m.plano_id = p.id
WHERE mat.status = 'Ativa'
GROUP BY p.nome;
