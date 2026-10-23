# Cadena Amparo CRM — ambiente de validação

Projeto **novo e independente**, sem dependência do CRM da Kumo. Next.js 15, Supabase Auth/Postgres, RLS, Kanban, cadastro de leads, responsáveis, histórico de atendimento e **importador manual Monday somente leitura**.

## Instalação

1. Crie projeto **novo** no Supabase da empresa. Execute `supabase/schema.sql` no SQL Editor.
2. Em Authentication → Providers, configure Email. **Desabilite inscrições públicas**. Configure Site URL com o domínio Vercel e redirect URL `https://SEU-DOMINIO/auth/callback`. Configure SMTP corporativo para convites em produção.
3. Crie usuário administrativo no painel Supabase Auth (Add user). Copie o UUID e execute no SQL Editor:
   `insert into public.profiles(id,full_name,role,active) values ('UUID_AQUI','Administrador MCMV','admin',true);`
4. Crie repositório Git **novo e privado** (por exemplo `amparo-crm`), envie este diretório e importe o repositório em Vercel → New Project.
5. Configure as variáveis do arquivo `.env.example` nos Environment Variables da Vercel. `SUPABASE_SERVICE_ROLE_KEY` e `MONDAY_API_TOKEN` são **somente servidor**, sem prefixo `NEXT_PUBLIC_`.
6. Rode `npm install && npm run build` (Vercel usa `npm run build`). Faça login no domínio publicado.

## Preparação da migração Monday (não grava no Monday)

- Configure `MONDAY_BOARD_ID` e `MONDAY_API_TOKEN` de um acesso com permissão mínima de leitura.
- Como **admin logado**, abra `GET /api/monday/preview`: exibe nome do quadro, colunas, grupos e amostra de oito registros. **Valide IDs e significados antes de importar**.
- Configure `MONDAY_PHONE_COLUMN_ID`, `MONDAY_EMAIL_COLUMN_ID`, `MONDAY_STATUS_COLUMN_ID`, `MONDAY_OWNER_COLUMN_ID` conforme a resposta. `MONDAY_NAME_COLUMN_ID` é desnecessário quando o nome do lead é o título do item.
- Convide os profissionais via endpoint protegido `POST /api/admin/invite` (body JSON `{ "email":"agente@empresa.com", "fullName":"Nome", "role":"agent", "mondayUserId":"123" }`). O e-mail do convite é gerado pelo Supabase. O ID do usuário Monday deve ser validado antes do vínculo.
- Realize a importação manual **somente após** validar a amostra: no browser autenticado, console DevTools, execute:
  `fetch('/api/monday/import',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({confirm:'IMPORTAR_MCMV'})}).then(r=>r.json()).then(console.log)`
- O importador consulta todos os itens até o limite de 3000 e rejeita a importação se ainda houver páginas. Faz UPSERT pela chave única `monday_item_id`, preservando atividades locais. **Reimportar substitui status/responsável do CRM pelos valores atuais do Monday**: use somente durante a migração inicial, antes da equipe trabalhar no CRM.
- O token Monday não permite escrita por meio deste código: nenhum endpoint de mutação Monday está implementado.

## Permissões

`admin` e `manager`: visualizar todos os leads e alterar atribuições. `agent`: visualizar e alterar somente leads atribuídos a si. Apenas admin pode executar importação e convidar colaboradores. Somente usuários com `profiles.active=true` podem acessar dados. Ações de atendimento são append-only para usuários comuns. A chave de serviço só é usada em rotas de servidor verificadas como administrativas.

## Cuidados de produção

- Recomendado: validar o conjunto inicial em projeto Supabase **de homologação**, antes de importar dados reais. Não inclua token/API key em commits.
- Há limite de 1000 leads exibidos na interface por consulta; para operação acima disso, adicionar paginação no frontend.
- O status importado do Monday pode diferir das etapas padrão do Kanban: ajuste `STEPS` após validar os status reais.
- Usuários sem perfil ativo não têm acesso a dados; inative perfis diretamente no Supabase se necessário.
- Este pacote **não sincroniza novas alterações feitas no Monday de forma contínua**, **não faz escrita no Monday**, e não inclui anexos/arquivos ou histórico anterior dos itens. Essas funções exigem validação posterior.
- Envio por WhatsApp ainda não está integrado; a opção "WhatsApp" em atendimento significa apenas registrar uma interação realizada.
- Branding independente Amparo CRM: amarelo forte `#FFD400`, preto `#0B0B0B` e superfícies neutras. Sem dependência visual da Cadena ou Kumo.
