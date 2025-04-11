-- Consulta 1: Junção dos produtos reportados como faltantes
WITH produtos_reportados AS (
    SELECT product_id_1 AS product_id
    FROM missing_items_data
    WHERE product_id_1 IS NOT NULL

    UNION ALL

    SELECT product_id_2 AS product_id
    FROM missing_items_data
    WHERE product_id_2 IS NOT NULL

    UNION ALL

    SELECT product_id_3 AS product_id
    FROM missing_items_data
    WHERE product_id_3 IS NOT NULL
)

SELECT 
  p.product_name,
  COUNT(pr.product_id) AS vezes_reportado
FROM produtos_reportados pr
JOIN products_data p ON pr.product_id = p.produc_id
GROUP BY p.product_name
ORDER BY vezes_reportado DESC;


-- -------------------------------------------------------

-- Consulta 2: Taxa de reclamação por entregador
WITH taxa_reclamacao AS (
  SELECT 
    o.driver_id,
    d.driver_name,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(DISTINCT m.order_id) AS pedidos_com_reclamacao,
    (1.0 * COUNT(DISTINCT m.order_id) / COUNT(DISTINCT o.order_id)) AS taxa_reclamacao
  FROM orders o
  LEFT JOIN missing_items_data m ON o.order_id = m.order_id
  LEFT JOIN drivers_data d ON o.driver_id = d.driver_id
  GROUP BY o.driver_id, d.driver_name
)

SELECT 
  driver_id,
  driver_name,
  total_pedidos,
  pedidos_com_reclamacao,
  ROUND(taxa_reclamacao * 100, 2) AS taxa_reclamacao_percentual
FROM taxa_reclamacao
WHERE taxa_reclamacao > (SELECT AVG(taxa_reclamacao) FROM taxa_reclamacao)
ORDER BY taxa_reclamacao_percentual DESC;


-- -------------------------------------------------------

-- Consulta 3: Criação da Flag de Reclamação pras métricas do dashboard
WITH pedidos_com_reclamacao AS (
  SELECT 
    DISTINCT order_id
  FROM missing_items_data
)

SELECT 
  o.order_id,
  o.region,
  o.driver_id,
  CASE 
    WHEN p.order_id IS NOT NULL THEN 1
    ELSE 0
  END AS flag_reclamacao
FROM orders o
LEFT JOIN pedidos_com_reclamacao p
ON o.order_id = p.order_id

-- -------------------------------------------------------

-- Consulta 4: Produtos faltando por faixa de preço
SELECT 
  CASE 
    WHEN p.price < 10 THEN 'Abaixo de $10'
    WHEN p.price BETWEEN 10 AND 50 THEN 'Entre $10 e $50'
    WHEN p.price BETWEEN 50 AND 200 THEN 'Entre $50 e $200'
    ELSE 'Acima de $200'
  END AS faixa_preco,
  COUNT(*) AS vezes_reportado_faltando
FROM (
    SELECT product_id_1 AS product_id FROM missing_items_data
    UNION ALL
    SELECT product_id_2 AS product_id FROM missing_items_data
    UNION ALL
    SELECT product_id_3 AS product_id FROM missing_items_data
) AS all_missing_products
JOIN products_data p ON all_missing_products.product_id = p.produc_id
GROUP BY faixa_preco
ORDER BY vezes_reportado_faltando DESC;

-- -------------------------------------------------------

-- Consulta 5: Padrão de repetição nos itens faltantes 
SELECT 
  order_id,
  product_id_1,
  product_id_2,
  product_id_3,
  CASE 
    WHEN product_id_1 = product_id_2 AND product_id_2 = product_id_3 THEN '3 iguais'
    WHEN product_id_1 = product_id_2 OR product_id_1 = product_id_3 OR product_id_2 = product_id_3 THEN '2 iguais'
    ELSE 'todos diferentes'
  END AS tipo_repeticao
FROM missing_items_data
ORDER BY tipo_repeticao ASC;
