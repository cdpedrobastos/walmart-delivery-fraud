WITH itens_faltando_por_pedido AS (
  SELECT
    order_id,
    (CASE WHEN product_id_1 IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN product_id_2 IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN product_id_3 IS NOT NULL THEN 1 ELSE 0 END) AS total_missing_items
  FROM missing_items_data
),

driver_summary AS (
  SELECT 
    o.driver_id,
    d.driver_name,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(DISTINCT m.order_id) AS pedidos_com_reclamacao,
    ROUND(100.0 * COUNT(DISTINCT m.order_id) / COUNT(DISTINCT o.order_id), 2) AS taxa_reclamacao_percentual,
    SUM(o.items_delivered) AS total_itens_entregues,
    SUM(COALESCE(im.total_missing_items, 0)) AS total_itens_faltando
  FROM orders o
  LEFT JOIN missing_items_data m ON o.order_id = m.order_id
  LEFT JOIN itens_faltando_por_pedido im ON o.order_id = im.order_id
  LEFT JOIN drivers_data d ON o.driver_id = d.driver_id
  GROUP BY o.driver_id, d.driver_name
)

SELECT *
FROM driver_summary
ORDER BY taxa_reclamacao_percentual DESC;
