# 📊 E-Commerce Dalilos — Cohort Retention & Lifetime Value (LTV) Analysis

Uma solução end-to-end de Business Intelligence desenvolvida para analisar a **retenção de clientes (Cohort Analysis)**, o **LifeTime Value (LTV)** e o faturamento recorrente do **E-commerce Dalilos**.

---

## 📌 1. Visão Geral do Projeto

No cenário do e-commerce moderno, o Custo de Aquisição de Clientes (CAC) é frequentemente elevado. Por isso, prever a vida útil financeira de um cliente e entender a eficiência da recompra ao longo do tempo é vital para a sustentabilidade da operação.

Este projeto entrega um **Dashboard Executivo e Interativo** no Power BI abastecido por uma arquitetura robusta no PostgreSQL, desenhado para responder a perguntas estratégicas da liderança:

* Qual é a taxa de retenção média das safras no Mês 1 ($M1$)?
* Quanto da receita total vem de recompras ($M1+$) vs. primeira compra ($M0$)?
* Como o LTV evolui à medida que a safra matura?
* Quais canais de aquisição, países e categorias de produto geram clientes com maior retenção e valor financeiro acumulado?

---

## 🎨 2. Design & Inspiração Visual

O design e a usabilidade do dashboard foram inspirados nas estruturas analíticas e visuais desenvolvidas pela **Goodly**, visando uma navegação fluida e focada em tomada de decisão.

* 🎬 **Referência visual:** [Vídeo Demonstrativo - Goodly (YouTube)](https://www.youtube.com/watch?v=I5LtnL9fxVA)
* 🎨 **Ícones:** Os ícones e elementos visuais utilizados na interface do dashboard foram obtidos na plataforma [Flaticon](https://www.flaticon.com/).

---

## 🎯 3. Metodologia & Regras de Negócio

Para garantir a **consistência estatística** e focar nos clientes genuinamente converted, aplicamos regras rigorosas de limpeza, segmentação e validação nas etapas de banco de dados e auditoria:

* **Base Convertida:** De um total de $8.000$ clientes cadastrados, a análise considera estritamente $7.200$ **clientes ativos**, cujos pedidos foram entregues (`order_status = 'Delivered'`) e não sofreram devolução (`returned = 0`).
* **Análise de Safra (Cohort):** O mês da primeira compra (`cohort_month`) define o grupo/safra do cliente.
* **Índice de Cohort (**$M0, M1, M2 \dots$**):** Mapeamento do deslocamento em meses entre a data da compra atual e a data de aquisição do cliente:

$$
\text{Cohort Index} = (\text{Ano}_{\text{compra}} - \text{Ano}_{\text{safra}}) \times 12 + (\text{Mês}_{\text{compra}} - \text{Mês}_{\text{safra}})
$$

---

## 🏗️ 4. Arquitetura da Solução

```
 ┌────────────────┐      ┌─────────────────────────┐      ┌──────────────────┐
 │ Data Source    │ ───> │ PostgreSQL (SQL Engine) │ ───> │ Power BI         │
 │ (Orders/Cust.) │      │ Viewvw_cohort_retention │      │ DAX & Dashboards │
 └────────────────┘      └─────────────────────────┘      └──────────────────┘
```

### 🐘 Layer 1: PostgreSQL (Data Engineering)

Toda a lógica pesada de transformação e agregação foi centralizada na View `vw_cohort_retention` utilizando CTEs (*Common Table Expressions*):

1. **`first_purchase`**: Identifica a data exata da 1ª compra de cada cliente, preservando as dimensões de `acquisition_channel`, `country` e `category`.
2. **`customer_activities`**: Mapeia todas as transações subsequentes elegíveis, somando receita mensal (`monthly_revenue`) e volume de pedidos (`monthly_orders`).
3. **`cohort_size`**: Calcula o volume inicial de clientes de cada safra ($M0$).
4. **`cohort_index_calc`**: Calcula o índice dinâmico ($M0, M1, M2 \dots$) e consolida o volume de clientes ativos, pedidos e faturamento.

### 📊 Layer 2: Power BI & Modelagem DAX

O Power BI consome a View limpa, permitindo alta performance em filtros cruzados (*Slicers* por Canal, País e Categoria).

* **Receita Recorrente (**$M1+$**):**

```dax
Receita Recorrente = 
CALCULATE(
    SUM('vw_cohort_retention'[cohort_revenue]),
    FILTER(
        ALL('vw_cohort_retention'[cohort_index]),
        'vw_cohort_retention'[cohort_index] > 0
    )
)
```

* **LTV Médio por Safra:**

```dax
LTV Medio = 
DIVIDE(
    SUM('vw_cohort_retention'[cohort_revenue]),
    MAX('vw_cohort_retention'[cohort_size]),
    0
)
```

---

## 📈 5. Principais KPIs & Resultados Encontrados

Após os testes de validação e auditoria de dados no Google Sheets:

| Métrica Executiva | Valor Apurado | Significado de Negócio |
| :--- | :--- | :--- |
| **Base Convertida** | **7.200** | Clientes com pelo menos 1 pedido entregue e não devolvido |
| **Receita Total Gerada** | **R\$ 10,92M** | Volume financeiro global de todas as safras |
| **Receita Recorrente (**$M1+$**)** | **R\$ 1,64M** | Faturamento gerado exclusivamente por recompras |
| **Volume de Compras** | **25.000** | Total de transações entregues e válidas na base |
| **Retenção Média no** $M1$ | **\~35% a 40%** | Taxa média de retorno de clientes no mês subsequente à compra |

---

## 🛡️ 6. Origem dos Dados & Conformidade (LGPD)

Os dados sintéticos utilizados neste projeto foram disponibilizados publicamente por **Meruva Kodanda** através do Kaggle.

* 🔗 **Fonte do Dataset:** [E-Commerce Customer Behavior and Sales (2020-2026) - Kaggle](https://www.kaggle.com/datasets/meruvakodandasuraj/e-commerce-customer-behavior-and-sales-20202026)
* 🔒 **Privacidade & LGPD:** Todas as informações contidas na base são anonimizadas e desprovidas de dados pessoais identificáveis (PII), respeitando as diretrizes da **Lei Geral de Proteção de Dados (LGPD)** e boas práticas globais de segurança da informação.

---

## ⚙️ 7. Como Replicar o Projeto

### Pré-requisitos
* PostgreSQL 13+
* Power BI Desktop

### Passo a Passo

1. **Clonar o Repositório:**
   ```bash
   git clone https://github.com/pauloviniciusrsouza/ecommerce-dalilos-cohort-retention.git
   cd ecommerce-dalilos-cohort-retention
   ```

2. **Configurar o Banco de Dados:**
   * Importe o dataset original para o PostgreSQL.
   * Execute o script de criação da View disponível na pasta `/sql/vw_cohort_retention.sql`.

3. **Abrir o Dashboard no Power BI:**
   * Abra o arquivo `/pbix/Cohort_Retention_Dashboard.pbix`.
   * Atualize as credenciais de conexão da fonte PostgreSQL para apontar para o seu ambiente local (`Transform Data -> Data source settings`).
   * Clique em **Refresh**.

---

## 👤 Autor

**Paulo Vinícius**  
*Analista de Dados & Business Intelligence*

* 💼 **LinkedIn:** [pauloviniciusrsouza](https://www.linkedin.com/in/pauloviniciusrsouza/)
* 🐙 **GitHub:** [pauloviniciusrsouza](https://github.com/pauloviniciusrsouza)
* 📧 **E-mail:** pauloviniciusrsouza@gmail.com

---
*Projeto desenvolvido para fins de portfólio e análise de inteligência de negócios do E-commerce Dalilos.*