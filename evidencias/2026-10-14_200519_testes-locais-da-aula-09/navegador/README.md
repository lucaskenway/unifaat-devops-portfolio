# Capturas de navegador — Aula 09 (Playwright)

Capturas reais da janela do navegador tiradas com o plugin **Playwright** (Google Chrome headless, viewport 1280×800) em 2026-10-14, a partir das URLs abaixo.
**Tudo local: nada aqui vem do GitHub.** A barra de endereço não aparece porque a captura é só da página.

| Arquivo | URL capturada | O que mostra |
|---------|---------------|--------------|
| `01_api-health.png` | `http://localhost:3009/health` | Container `technova-api:aula09` respondendo ao health check |
| `02_api-orders.png` | `http://localhost:3009/api/orders` | Rota de pedidos da API rodando no container |
| `03_coverage-report.png` | `aula-09/technova-api/coverage/lcov-report/index.html` (servido em `127.0.0.1:8099`) | Relatório de coverage do Jest (89,28% statements) |
| `04_ai-review-pr-inseguro.png` | `review-inseguro.html` | Comentário que o AI review postaria no PR inseguro: 3 CRITICAL, 2 WARNING, gate **bloqueado** |
| `05_ai-review-pr-corrigido.png` | `review-corrigido.html` | Mesmo review no PR corrigido: nenhum achado, gate aprovado |

`04` e `05` são **pré-visualizações**: o Markdown real gerado por `.github/scripts/ai-review.js` (itens #009 e #010 desta sessão), convertido para HTML com `marked` e aberto no navegador. A faixa amarela no topo da imagem diz isso. Os HTML usados estão nesta pasta.

## SHA-256

```
8ccda437b24b0545899bf8a231c9072f2e75736a30453e9af01c76c27226cab5  01_api-health.png
f55b0f4e2088471ffba298721161e44fa511a6b25121a24698e1800586826796  02_api-orders.png
b7bd2ee7fd8b73844b8aad68dcd7e485487e1e6053274990a21ae0fa9ad46c8b  03_coverage-report.png
3cbfab4efd9c1164513519cc688b6d52bfb345723a9ef5338f018a5cb2b48921  04_ai-review-pr-inseguro.png
01c04c0518a4997c25401370942b0753ebd317f1339d8189eebe105b4615d169  05_ai-review-pr-corrigido.png
c80e7c082bf6d8f764cc226e441da70e4b565e9a67d43ad42cca4e49059553a3  review-corrigido.html
69c36ef6905c90405efa05a59fa77e79871fcf9b739888615524671389366a5f  review-inseguro.html
```
