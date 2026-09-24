# 📊 E-Commerce Dalilos — Cohort Retention & Lifetime Value (LTV) Analysis

Uma solução end-to-end de Business Intelligence desenvolvida para analisar a **retenção de clientes (Cohort Analysis)**, o **LifeTime Value (LTV)** e o faturamento recorrente do **E-commerce Dalilos**.

<p align="center"> <img width="577" height="324" alt="img_dashboard_powerbi" src="https://github.com/user-attachments/assets/55e8c332-8c99-45a0-afa7-1a4835333a45" /> </p>

---

## 📌 1. Visão Geral do Projeto

No cenário do e-commerce moderno, o Custo de Aquisição de Clientes (CAC) é frequentemente elevado. Por isso, prever a vida útil financeira de um cliente e entender a eficiência da recompra ao longo do tempo é vital para a sustentabilidade da operação.

Desenvolvi este **Dashboard Executivo e Interativo** no Power BI abastecido por uma arquitetura robusta no PostgreSQL, projetado para responder às seguintes perguntas estratégicas da liderança:

* Qual é a taxa de retenção média das safras no Mês 1 ($M1$)?
* Quanto da receita total vem de recompras ($M1+$) vs. primeira compra ($M0$)?
* Como o LTV evolui à medida que a safra matura?
* Quais canais de aquisição, países e categorias de produto geram clientes com maior retenção e valor financeiro acumulado?

---

## 🎨 2. Design, Prototipação & Inspiração Visual

### 🖌️ Prototipação no Excalidraw
Antes de escrever qualquer linha de código ou criar telas no Power BI, **planejei e desenhei todo o protótipo da análise no Excalidraw**. Defini previamente quais dados seriam necessários, quais KPIs trariam valor real ao negócio e qual seria o layout inicial. O painel evoluiu de forma orgânica ao longo do desenvolvimento, mas a estrutura conceitual manteve a clareza e a objetividade desenhadas no protótipo.

<p align="center"> <img width="600" height="337" alt="img_excalidraw" src="https://github.com/user-attachments/assets/2dbbaa26-dff6-434d-8a51-b44bba9ea5f5" /> </p>

### 🎬 Referências de Design
O design e a usabilidade do dashboard foram inspirados nas estruturas analíticas e visuais desenvolvidas pela **Goodly**, visando uma navegação fluida e focada em tomada de decisão.

* 🎬 **Referência visual:** [Build a Cohort Analysis Dashboard in Power BI | Step-by-Step - Goodly (YouTube)](https://www.youtube.com/watch?v=I5LtnL9fxVA)
* 🎨 **Ícones:** Os ícones e elementos visuais utilizados na interface do dashboard foram obtidos na plataforma [Flaticon](https://www.flaticon.com/).

---

## 🎯 3. Metodologia & Regras de Negócio

Para garantir a **consistência estatística** e focar nos clientes genuinamente convertidos, apliquei regras rigorosas de limpeza, segmentação e validação nas etapas de banco de dados e auditoria:

* **Base Convertida:** De um total de $8.000$ clientes cadastrados, considerei estritamente $7.200$ **clientes ativos**, cujos pedidos foram entregues (`order_status = 'Delivered'`) e não sofreram devolução (`returned = 0`).
* **Análise de Safra (Cohort):** O mês da primeira compra (`cohort_month`) define o grupo/safra do cliente.
* **Índice de Cohort (**$M0, M1, M2 \dots$**):** Mapeamento do deslocamento em meses entre a data da compra atual e a data de aquisição do cliente:

$$
\text{Cohort Index} = (\text{Ano}_{\text{compra}} - \text{Ano}_{\text{safra}}) \times 12 + (\text{Mês}_{\text{compra}} - \text{Mês}_{\text{safra}})
$$

---

## 🏗️ 4. Arquitetura da Solução & Validação

```
 ┌────────────────┐      ┌─────────────────────────┐      ┌─────────────────┐      ┌──────────────────┐
 │ Data Source    │ ───> │ PostgreSQL (SQL Engine) │ ───> │ Google Sheets   │ ───> │ Power BI         │
 │ (Orders/Cust.) │      │ View vw_cohort_retention│      │ (Auditoria)     │      │ DAX & Dashboards │
 └────────────────┘      └─────────────────────────┘      └─────────────────┘      └──────────────────┘
```

### 🐘 Layer 1: Engenharia de Dados no PostgreSQL
Centralizei toda a lógica pesada de transformação e agregação na View `vw_cohort_retention` utilizando CTEs (*Common Table Expressions*):

1. **`first_purchase`**: Identifiquei a data exata da 1ª compra de cada cliente, preservando as dimensões de `acquisition_channel`, `country` e `category`.
2. **`customer_activities`**: Mapeei todas as transações subsequentes elegíveis, somando receita mensal (`monthly_revenue`) e volume de pedidos (`monthly_orders`).
3. **`cohort_size`**: Calculei o volume inicial de clientes de cada safra ($M0$).
4. **`cohort_index_calc`**: Calculei o índice dinâmico ($M0, M1, M2 \dots$) e consolidei o volume de clientes ativos, pedidos e faturamento.

<p align="center"> <img width="957" height="540" alt="img_postgresql" src="https://github.com/user-attachments/assets/ec8822f6-216c-46f0-b420-85a6773fa2f2" /> </p>

### 📑 Layer 2: Auditoria Cruzada no Google Sheets
Em **todas as etapas do projeto, realizei validações constantes no Google Sheets**. Exportei amostras dos dados e agregados do PostgreSQL para conferir se os totais de clientes por safra, faturamento acumulado, contagens de pedidos e índices de cohort batiam exatamente com os cálculos esperados. Essa auditoria manual garantiu que nenhuma métrica chegasse com inconsistência ao Power BI.

<p align="center"> <img width="952" height="480" alt="img_sheets" src="https://github.com/user-attachments/assets/901ba72c-aecc-4e41-a4f0-b121c6ec190d" /> </p>

### 📊 Layer 3: Power BI & Modelagem DAX
Conectei o Power BI à View limpa e auditada, construindo uma modelagem em Star Schema de alta performance com filtros cruzados (*Slicers* por Canal, País e Categoria).

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
VAR ReceitaTotal = SUM('public vw_cohort_retention'[cohort_revenue])
VAR ClientesValidos = [Total Clientes Cadastrados]

RETURN
    DIVIDE(ReceitaTotal, ClientesValidos, 0)
```

* **Retenção Média no Mês 1 ($M1$):**
```dax
Retencao Media M1 = 
VAR AtivosM1 = 
    CALCULATE(
        DISTINCTCOUNT('public vw_cohort_retention'[customer_id]),
        'public vw_cohort_retention'[cohort_index] = 1
    )

VAR SafrasComM1 = 
    CALCULATETABLE(
        VALUES('public vw_cohort_retention'[cohort_month]),
        'public vw_cohort_retention'[cohort_index] = 1
    )

VAR BaseM0 = 
    CALCULATE(
        DISTINCTCOUNT('public vw_cohort_retention'[customer_id]),
        'public vw_cohort_retention'[cohort_index] = 0,
        'public vw_cohort_retention'[cohort_month] IN SafrasComM1
    )

RETURN
    DIVIDE(AtivosM1, BaseM0, 0)
```

---

## 📈 5. Principais KPIs & Resultados Encontrados

Após concluir as etapas de modelagem, transformações de dados e testes de validação cruzada no Google Sheets e no Power BI, os números finais apurados para o **E-commerce Dalilos** foram:

| Métrica Executiva | Valor Apurado | Significado de Negócio |
| :--- | :---: | :--- |
| **Base Convertida** | **7.401** | Clientes com pelo menos 1 pedido entregue e não devolvido |
| **Volume de Compras** | **20.497** | Total de transações entregues e válidas na base |
| **Retenção Média no** $M1$ | **3,75%** | Taxa real de retorno dos clientes no primeiro mês após a compra inicial |
| **LTV Médio** | **R$ 349,29** | Valor financeiro médio gerado por cada cliente ao longo do tempo de vida |
| **Receita de Recompra** | **R$ 1,64M** | Faturamento acumulado vindo exclusivamente de recompras ($M1+$) |

---

## 🛡️ 6. Origem dos Dados & Conformidade (LGPD)

Os dados sintéticos utilizados neste projeto foram disponibilizados publicamente por **Meruva Kodanda** através do Kaggle.

* 🔗 **Fonte do Dataset:** [E-Commerce Customer Behavior and Sales (2020-2026) - Kaggle](https://www.kaggle.com/datasets/meruvakodandasuraj/e-commerce-customer-behavior-and-sales-20202026)
* 🔒 **Privacidade & LGPD:** Todas as informações contidas na base são totalmente anonimizadas e desprovidas de dados pessoais identificáveis (PII), respeitando as diretrizes da **Lei Geral de Proteção de Dados (LGPD)** e boas práticas globais de segurança da informação.

---

## ⚙️ 7. Como Replicar o Projeto

### Pré-requisitos
* PostgreSQL 17+
* Power BI Desktop

### Passo a Passo
1. **Clonar o Repositório:**
   ```bash
   git clone https://github.com/pauloviniciusrsouza/ecommerce-dalilos-cohort-retention.git
   cd ecommerce-dalilos-cohort-retention
   ```

2. **Configurar o Banco de Dados:**
   * Importe o dataset original para o PostgreSQL.
   * Execute o script de criação da View disponível na pasta `/sql/script_vw_cohort_retention.sql`.

3. **Abrir o Dashboard no Power BI:**
   * Abra o arquivo `/pbix/Cohort_Retention_Dashboard.pbix`.
   * Atualize as credenciais de conexão da fonte PostgreSQL para apontar para o seu ambiente local (`Transform Data -> Data source settings`).
   * Clique em **Refresh**.

---

## 🎬 Vídeo Demonstrativo
Confira a apresentação do dashboard em funcionamento e o storytelling analítico na [publicação do LinkedIn](link).

---

## 👤 Autor

**Paulo Vinícius**  
*Analista de Dados & Business Intelligence*

* 💼 **LinkedIn:** [pauloviniciusrsouza](https://www.linkedin.com/in/pauloviniciusrsouza/)
* 🐙 **GitHub:** [pauloviniciusrsouza](https://github.com/pauloviniciusrsouza)
* 📧 **E-mail:** pauloviniciusrsouza@gmail.com

*Projeto desenvolvido para fins de portfólio e análise de inteligência de negócios do E-commerce Dalilos.*
